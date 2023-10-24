class Billing::MakePurchase < ApplicationInteractor
  def call(product:, user:)
    yield proccess_payment(user:, product:)
    product_access = yield grant_access_to_user(user:, product:)
    yield notify_user(user:, product_access:)
  end

  private

  def proccess_payment(user:, product:)
    payment_result = CloudPayment.proccess(
      user_uid: user.cloud_payments_uid,
      amount_cents: params[:amount] * 100,
      currency: 'RUB'
    )
    payment_result.succes? ? Success(:ok) : Failure(:payment_fault)
  end

  def grant_access_to_user(user:, product:)
    ProductAccess.create!(user: current_user, product:)
    Success(:ok)
  end

  def notify_user(user:, product_access:)
    OrderMailer.product_access_email(product_access).deliver_later
    Success(:ok)
  end
end