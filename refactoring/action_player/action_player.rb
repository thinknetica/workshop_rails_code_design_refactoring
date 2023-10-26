class ActionPlayer < ApplicationRecord
  validates :phone, uniqueness: { scope: :promo_action, message: 'Участник уже существует' }, allow_blank: true
  validates :email, uniqueness: { scope: :promo_action, message: 'Участник уже существует' }, allow_blank: true
  validate :phone_or_email_exists
  delegate :telegram_id, to: :player

  serialize :data, HashSerializer

  attr_accessor :rank, :retail_chain, :retail_chain_checks_count, :checks_count

  store_accessor :data, :daily_winner, :weekly_winner, :monthly_winner, :big_winner,
                 :special_winner, :super_winner, :birthday, :daily_prises_count,
                 :weekly_prises_count, :monthly_prises_count, :big_prises_count,
                 :guaranteed_prises_count, :special_prises_count
  devise :database_authenticatable

  EDITABLE_FIELDS = %w[last_name first_name middle_name loyalty_card email region city birthday comment phone].freeze
  EDITABLE_BY_MANAGER = %w[loyalty_card comment phone].freeze
  EDITABLE_BY_COMPANY_MANAGER = %w[loyalty_card comment phone].freeze
  audited only: EDITABLE_FIELDS, on: [:update]

  validates :promo_action, :player, presence: true
  validate  :age_of_majority, on: :create

  belongs_to :player
  belongs_to :promo_action, counter_cache: true
  belongs_to :import, optional: true
  belongs_to :user, foreign_key: :phone, primary_key: :phone, optional: true
  has_many :checks, dependent: :destroy
  has_many :check_requests, dependent: :destroy
  has_many :smses, class_name: 'Sms', dependent: :destroy
  has_many :action_player_messages, dependent: :destroy
  has_many :payouts, through: :checks
  has_many :prises, through: :checks

  has_one :anketa

  before_validation(on: :create) do
    self.daily_winner = false
    self.weekly_winner = false
    self.monthly_winner = false
    self.big_winner = false
    self.special_winner = false
    true
  end

  before_save :remove_region_from_city
  before_save :set_full_name
  before_create :set_crm_status, unless: :skip_callbacks
  scope :ordered, -> { order('created_at DESC') }
  scope :order_by_checks_count, lambda { |order_direction|
                                  left_joins(:checks)
                                    .group(:id)
                                    .order("COUNT(checks.id) #{order_direction}")
                                }

  class << self
    def by_session_id(session_id)
      return unless session_id

      session_hash = Digest::SHA256.hexdigest(session_id)
      find_by(token: session_hash) || find_by(admin_token: session_hash)
    end

    def generate_password
      return 'password' unless Rails.env.production?

      SecureRandom.urlsafe_base64.chars.map(&:ord).join[2, 6]
    end

    def by_phone(phone)
      find_by(phone: phone.to_s)
    end

    def find_or_register(promo_action, phone)
      player        = Player.find_or_create_by(phone: phone)
      action_player = player.action_players.find_by(promo_action: promo_action)

      if action_player.present?
        action_player
      else
        player.action_players.create(
          phone: phone,
          promo_action: promo_action,
          automatic_registration: true
        )
      end
    end

    def fields_for_edit(role: nil)
      return {} unless role

      EDITABLE_FIELDS.each_with_object({}) { |field, res| res[field] = role_can_change_field?(role, field) }
    end

    private

    def role_can_change_field?(role, field)
      return true if role.to_s == 'admin'
      return EDITABLE_BY_MANAGER.include?(field.to_s) if role.to_s == 'manager'
      return EDITABLE_BY_COMPANY_MANAGER.include?(field.to_s) if role.to_s == 'company_manager'

      false
    end
  end

  def activity
    @activity ||= PlayerActivity.find_by(player_id: player_id)
  end

  def reset_session!
    update(token: nil)
  end

  def send_sms(message, secret = nil)
    SmsSender.send_to_action_player(self, message, secret: secret)
  end

  def winner?
    winner
  end

  def win!(prise)
    if prise.draw_type.present?
      currrent_prises_count = public_send("#{prise.draw_type}_prises_count").to_i
      update!(
        winner: true,
        "#{prise.draw_type}_winner" => true,
        "#{prise.draw_type}_prises_count" => currrent_prises_count + 1
      )
    else
      update!(winner: true)
    end
  end

  def cancel_win!(prise)
    update!(winner: checks.winners.any?)
    if prise.draw_type.present? && !prise.draw_type_guaranteed?
      raw_count = public_send("#{prise.draw_type}_prises_count")
      count = (raw_count.to_i.positive? ? raw_count - 1 : 0)
      update!("#{prise.draw_type}_winner" => count.positive?, "#{prise.draw_type}_prises_count" => count)
    end
  end

  def full_json
    {
      last_name: last_name,
      first_name: first_name,
      middle_name: middle_name,
      blocked: blocked,
      phone: phone,
      email: email
    }
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def live_crm_status
    other_actions_players = player.action_players.reject { |ap| ap == self }
    return :empty if other_actions_players.empty?

    summary = other_actions_players.map { |ap| ap.data[:summary] }.compact
    return :clean if summary.empty?

    block_info = summary.inject(false) do |memo, info|
      memo || info[:checks_blocked] || info[:self_blocked]
    end

    block_info ? :suspect : :clean
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def has_prise?(prise)
    checks.winners.any? && prises.pluck(:slug).include?(prise.slug)
  end

  def reset_failed_attempts!
    update!(
      failed_login_attempts_count: 0,
      last_failed_login_attempt: nil,
      lock_login_until: nil
    )
  end

  def track_failed_login_attempt!
    current_time = Time.zone.now
    self.failed_login_attempts_count =
      if last_failed_login_attempt.present? && last_failed_login_attempt + 15.minutes > current_time
        failed_login_attempts_count + 1
      else
        1
      end
    self.last_failed_login_attempt = current_time
    self.lock_login_until = current_time + 15.minutes if failed_login_attempts_count > 5
    save!
  end

  def able_to_login?
    lock_login_until.nil? || lock_login_until < Time.zone.now
  end

  def hidden_phone
    "#{Phonelib.parse(phone).international[0..5]} *** #{Phonelib.parse(phone).international[-2..]}"
  end

  def stuff?
    return unless user

    user.admin? || user.manage?(promo_action)
  end

  private

  def phone_or_email_exists
    return if phone.present? || email.present?

    errors.add(:base, 'Телефон или электронная почта должны быть определены')
  end

  def remove_region_from_city
    self.city = city.sub(/#{region}\W\s/, '') if city.present?
  end

  def set_full_name
    self.full_name = "#{last_name} #{first_name} #{middle_name}".squish.presence
  end

  def set_crm_status
    self.crm_status = live_crm_status
  end

  def age_of_majority
    return unless birthday.present?

    treshold_date = Date.today - 18.years
    errors.add(:birthday, 'Возраст участника не может быть меньше 18 лет') if birthday > treshold_date
  end
end
