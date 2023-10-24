class ApplicationBilling
  def initializer(product)
    @product = product
  end

  def make_purchase(user)
    payment_result = gateway_purchase(user)
    if payment_result.successful?
      product_access = grant_access_to_product(user)
      notify_user(product_access)
    end

    payment_result
  end

  def make_gift(user)
    product_access = grant_access_to_product(user)
    notify_user(product_access)
  end

  private

  attr_reader :product

  def gateway_purchase(user)
    payment_gateway.proccess(
      user_uid: user.cloud_payments_uid,
      amount_cents: product.amount_cents,
      currency: 'RUB'
    )
  end

  def grant_access_to_product(user)
    ProductAccess.create(user:, product:)
  end

  def notify_user(product_access)
    OrderMailer.product_access_email(product_access).deliver_later
  end

  def payment_gateway
    CloudPayment
  end
end