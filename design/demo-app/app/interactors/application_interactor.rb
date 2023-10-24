class ApplicationInteractor
  include Dry::Monads::Do
  include Dry::Monads::Result::Mixin

  def self.call(...)
    new.call(...)
  end
end