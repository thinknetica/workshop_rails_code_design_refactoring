module Billing::Operations
  class Purchase
    step :gateway_purchase
    step :validate_purchase_result
    step :grant_access_to_product
    step :notify_user

    def gateway_purchase(ctx, params)
      ctx[:payment_result] = payment_gateway.proccess(
        user_uid: params[:user].cloud_payments_uid,
        amount_cents: params[:product].amount_cents,
        currency: 'RUB'
      )
    end

    def validate_purchse_result(ctx, params)
      ctx[:payment_result].successful?
    end

    def grant_access_to_product(ctx, params)
      ctx[:product_access] = ProductAccess.create(
        user: params[:user],
        product: params[:user]
      )
    end

    def notify_user(ctx, params)
      OrderMailer.product_access_email(ctx[:product_access]).deliver_later
    end

    def payment_gateway
      CloudPayment
    end
  end
end