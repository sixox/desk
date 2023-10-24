class PaymentOrdersController < ApplicationController

	before_action :authenticate_user!
	before_action :set_payment_order, only: %i[ show edit update destroy ]
	before_action :set_form_items, only: %i[ new edit ] 
	



	def show
	end

	def index
		@payment_orders = PaymentOrder.all.reverse
	end

	def new	
		@payment_order = current_user.payment_orders.new
	end


	def edit
	end

	def confirm
		@payment_order = PaymentOrder.find(params[:id])
		if current_user.ceo?
			@payment_order.ceo_confirm = true
		elsif current_user.procurement?
			@payment_order.coo_confirm = true
			if @payment_order.user.procurement?
				@payment_order.department_confirm = true
			end
		elsif current_user.accounting?
			@payment_order.accounting_confirm = true
			if @payment_order.user.accounting?
				@payment_order.department_confirm = true
			end
		elsif current_user.is_manager
			@payment_order.department_confirm = true
		end
		
		respond_to do |format|
			if @payment_order.save
				format.html { redirect_to payment_orders_path }
			else
				format.html { render :show, status: :unprocessable_entity }
        		format.json { render json: @payment.errors, status: :unprocessable_entity }

			end
		end




	end

	def create
		@payment_order = current_user.payment_orders.new(payment_order_params)
		@payment_order.user = current_user
		respond_to do |format|
			if @payment_order.save
				format.turbo_stream { render turbo_stream: turbo_stream.prepend('payment_order_items', partial: 'payment_orders/payment_order', locals: { payment_order: @payment_order }) }
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'payment_orders/form', modal_title: 'Add payment_order' })}
			end
		end
	end

	def update
		respond_to do |format|
			if @payment_order.update(payment_order_params)
				format.turbo_stream { render turbo_stream: turbo_stream.replace("payment_order_item_#{@payment_order.id}", partial: 'payment_orders/payment_order', locals: { payment_order: @payment_order }) }
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'payment_orders/form', modal_title: 'Edit payment_order ' })}
			end
		end
	end

	def destroy
		respond_to do |format|
			@payment_order.destroy
			format.turbo_stream { render turbo_stream: turbo_stream.remove("payment_order_item_#{@payment_order.id}") }
		end
	end




	private

	def set_payment_order
		@payment_order = PaymentOrder.find(params[:id])	
	end

	def set_form_items
		@ballances = Ballance.all.reverse
		@projects = Project.all.reverse
		@bookings = Booking.all.reverse
		@spis = Spi.all.reverse
		@scis = Sci.all.reverse

	end


	def payment_order_params
		params.require(:payment_order).permit(
			:reference,
			:amount,
			:from,
			:to,
			:receiver,
			:receiver_account,
			:details,
			:exchange_rate,
			:exchange_amount,
			:have_factor,
			:inserted,
			:payment_type,
			:department_confirm,
			:accounting_confirm,
			:ceo_confirm,
			:status,
			:currency,
			:user_id,
			:project_id,
			:sci_id,
			:spi_id,
			:ballance_id,
			:booking_id,
			:is_rahkarsazan,
			:document,
			:coo_confirm,
			:receipt
			)
	end


end