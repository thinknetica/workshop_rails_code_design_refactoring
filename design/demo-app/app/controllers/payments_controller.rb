class PaymentsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    purchase_result = Billing::MakePurchase.(user: current_user, product:)

    if purchase_result.success?
      redirect_to :successful_payment_path
    else
      redirect_to :failed_payment_path, note: purchase_result.error_message
    end
  end
end


class PaymentsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    purchase_result = Billing::Operations::Purchase.(params: {user: current_user, product:})

    if purchase_result.successful?
      redirect_to :successful_payment_path
    else
      redirect_to :failed_payment_path, note: purchase_result.error_message
    end
  end
end

# class PaymentsController < ApplicationController
#   def create
#     product = Product.find(params[:product_id])

#     if params[:secret_purchase] == 'kasljdf;lkjqoiwehrbkjh187'
#       payment_result = CloudPayment.proccess(
#         user_uid: current_user.cloud_payments_uid,
#         amount_cents: params[:amount] * 100,
#         currency: 'RUB'
#       )
#     end

#     if params[:secret_purchase] == 'kasljdf;lkjqoiwehrbkjh187' && payment_result[:status] == 'completed'
#       product_access = ProductAccess.create(user: current_user, product:)
#       OrderMailer.product_access_email(product_access).deliver_later
#       redirect_to :successful_payment_path
#     else
#       redirect_to :failed_payment_path, note: 'Что-то пошло не так'
#     end
#   end
# end


# class PaymentsController < ApplicationController
#   def create
#     product = Product.find(params[:product_id])
#     purchase_result = ApplicationBilling.new(product).make_purchase(current_user)

#     if purchase_result.successful?
#       redirect_to :successful_payment_path
#     else
#       redirect_to :failed_payment_path, note: purchase_result.error_message
#     end
#   end
# end
