class CustomersController < ApplicationController
	before_action :authenticate_user!
	before_action :set_customer, only: %i[ edit update destroy ]

	def index
		@customers = Customer.all
	end

	def show
	end


	def new
		@customer = current_user.customers.new
	end

	def edit
	end

	def create
	  @customer = current_user.customers.new(customer_params)
	  respond_to do |format|
	    if @customer.save
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.prepend('customer_items', partial: 'customers/customer', locals: { customer: @customer }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'Customer was successfully created.' })
	        ]
	      end
	    else
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'customers/form', modal_title: 'Add Customer' }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { alert: 'Error creating customer.' })
	        ]
	      end
	    end
	  end
	end


	def update
	  respond_to do |format|
	    if @customer.update(customer_params)
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.replace("customer_item_#{@customer.id}", partial: 'customers/customer', locals: { customer: @customer }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'Customer was successfully updated.' })
	        ]
	      end
	    else
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'customers/form', modal_title: 'Edit Customer' }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { alert: 'Error updating customer.' })
	        ]
	      end
	    end
	  end
	end


	def destroy
		respond_to do |format|
			@customer.destroy
			format.turbo_stream { render turbo_stream: turbo_stream.remove("customer_item_#{@customer.id}") }
		end
	end


	private

	def set_customer
		@customer = Customer.find(params[:id])
	end

	def customer_params
		params.require(:customer).permit(:name, :nickname, :company)
	end

end