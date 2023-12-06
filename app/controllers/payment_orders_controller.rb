class PaymentOrdersController < ApplicationController

	before_action :authenticate_user!
	before_action :set_payment_order, only: %i[ show edit reject confirm update destroy ]
	before_action :set_form_items, only: %i[ new edit ] 
	



	def show
	end

	def index
		@in_page = "index"
		cu = current_user
		if (current_user.is_manager && current_user.procurement?) || (current_user.admin? || current_user.accounting? || current_user.ceo? )
			@payment_orders = PaymentOrder.order(created_at: :desc).page(params[:page]).per(6)
		else
			@payment_orders = PaymentOrder.filtered_by_role(current_user).order(created_at: :desc).page(params[:page]).per(6)
		end

	end

	def new	
		@payment_order = current_user.payment_orders.new
	end


	def edit
	end

	def reject
		if current_user.ceo?
			ro = "CEO"
		elsif current_user.procurement?
			ro = "COO"
		else
			ro = "Manager"
		end
		@payment_order.reject_by = ro
		
		@payment_order.rejected_at = Time.now
		respond_to do |format|
			if @payment_order.save
				format.html { redirect_to payment_orders_path }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @payment.errors, status: :unprocessable_entity }

			end
		end

	end

	def confirm
		link_to_action = "/payment_orders/#{params[:id]}"
		coo = User.find(9)
		ceo = User.find(19)
		farzin = User.find(4)
		accounting_users = User.where(role: 'accounting')

		if current_user.ceo?
			@payment_order.ceo_confirm = true
			@payment_order.ceo_confirmed_at = Time.now
			accounting_users.each do |accounting_user|
				accounting_user.notifications.create(payment_id: params[:id], message: 'Payment Order Confirmed and wait for payment',is_read: false, link_to_action: link_to_action)
			end


		elsif current_user.procurement?
			@payment_order.coo_confirm = true
			@payment_order.coo_confirmed_at = Time.now
			if @payment_order.user.procurement?
				@payment_order.department_confirm = true
				@payment_order.department_confirmed_at = Time.now
			end
			if !@payment_order.accounting_confirm
				farzin.notifications.create(payment_id: params[:id], message: 'Confirmation required for Payment order',is_read: false, link_to_action: link_to_action)
			end



		elsif current_user.accounting?
			@payment_order.accounting_confirm = true
			@payment_order.accounting_confirmed_at = Time.now
			if @payment_order.user.accounting?
				@payment_order.department_confirm = true
				@payment_order.department_confirmed_at = Time.now
			end
			if !@payment_order.coo_confirm
				coo.notifications.create(payment_id: params[:id], message: 'Confirmation required for Payment order',is_read: false, link_to_action: link_to_action)
			end
			if @payment_order.coo_confirm && !@payment_order.ceo_confirm
				ceo.notifications.create(payment_id: params[:id], message: 'Confirmation required for Payment order',is_read: false, link_to_action: link_to_action)
			end

		elsif current_user.is_manager && !current_user.procurement?
			@payment_order.department_confirm = true
			@payment_order.department_confirmed_at = Time.now
			if !@payment_order.coo_confirm
				coo.notifications.create(payment_id: params[:id], message: 'Confirmation required for Payment order',is_read: false, link_to_action: link_to_action)
			end

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

	def delivered
		@payment_order = PaymentOrder.find(params[:id])
		@payment_order.delivered_at = Time.now
		respond_to do |format|
			if @payment_order.update(delivery_confirm: true)
				format.html { redirect_to payment_orders_path }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @payment.errors, status: :unprocessable_entity }
			end

		end
	end

	def not_paid
		@in_page = "notp"
		current_user_role = current_user.role
		if (current_user.is_manager && current_user.procurement?) || (current_user.admin? || current_user.accounting? || current_user.ceo? )
			@payment_orders = PaymentOrder.where(status: 'wait for payment').order(created_at: :desc).page(params[:page]).per(6)
		else
			@payment_orders = PaymentOrder.joins(:user).where(users: { role: current_user.role }).where(status: 'wait for payment').order(created_at: :desc).page(params[:page]).per(6)
		end
		render 'index'
	end

	def not_confirmed
		@in_page = "not confirmed"
		current_user_role = current_user.role
		if (current_user.is_manager && current_user.procurement?) || (current_user.admin? || current_user.accounting? || current_user.ceo? )
			@payment_orders = PaymentOrder.where(status: 'wait for confirm').order(created_at: :desc).page(params[:page]).per(6)
		else
			@payment_orders = PaymentOrder.joins(:user).where(users: { role: current_user.role }).where(status: 'wait for confirm').order(created_at: :desc).page(params[:page]).per(6)

		end
		render 'index'
	end

	def finished
		@in_page = "finished"
		current_user_role = current_user.role
		if (current_user.is_manager && current_user.procurement?) || (current_user.admin? || current_user.accounting? || current_user.ceo? )
			@payment_orders = PaymentOrder.where(status: 'delivered').order(created_at: :desc).page(params[:page]).per(6)
		else
			@payment_orders = PaymentOrder.joins(:user).where(users: { role: current_user.role }).where(status: 'delivered').order(created_at: :desc).page(params[:page]).per(6)

		end
		render 'index'
	end

	def pending
		@in_page = "pending"
		current_user_role = current_user.role
		if (current_user.is_manager && current_user.procurement?) || (current_user.admin? || current_user.accounting? || current_user.ceo? )
			@payment_orders = PaymentOrder.where.not(status: 'delivered').order(created_at: :desc).page(params[:page]).per(6)
		else

			@payment_orders = PaymentOrder.joins(:user).where(users: { role: current_user.role }).where.not(status: 'delivered').order(created_at: :desc).page(params[:page]).per(6)
		end
		render 'index'
	end

	def not_delivered
		@in_page = "notd"
		current_user_role = current_user.role
		if (current_user.is_manager && current_user.procurement?) || (current_user.admin? || current_user.accounting? || current_user.ceo? )
			@payment_orders = PaymentOrder.where(status: 'wait for delivery').order(created_at: :desc).page(params[:page]).per(6)
		else
			@payment_orders = PaymentOrder.joins(:user).where(users: { role: current_user.role }).where(status: 'wait for delivery').order(created_at: :desc).page(params[:page]).per(6)
		end
		render 'index'
	end

	def mine
		@in_page = "mine"
		@payment_orders = current_user.payment_orders.order(created_at: :desc).page(params[:page]).per(6)
		render 'index'
	end

	def confirmable
		@in_page = "confirmable"
		cu = current_user
		if current_user.is_manager
			if cu.ceo?
				@payment_orders = PaymentOrder.not_confirmed_by_ceo_but_by_coo_and_accounting.order(created_at: :desc)
			elsif cu.procurement?
				@payment_orders = PaymentOrder.not_confirmed_by_coo.order(created_at: :desc)
			elsif cu.accounting?
				accounting_pos = PaymentOrder.filtered_by_role_and_dep_confirm(cu)
				@payment_orders = PaymentOrder.not_confirmed_by_accounting.order(created_at: :desc)
				@payment_orders += accounting_pos
				@payment_orders.sort_by!(&:created_at).reverse!
			else
				@payment_orders = PaymentOrder.filtered_by_role_and_dep_confirm(cu).order(created_at: :desc)
			end

			@payment_orders = Kaminari.paginate_array(@payment_orders).page(params[:page]).per(6)
		end

		render 'index'

	end

	def reports
		selected_month = Date.parse(params[:selected_month]) if params[:selected_month].present?

		@not_paid_dollar = PaymentOrder.filtered_orders('wait for payment', 'dollar', selected_month).joins(:user)
                    .select('payment_orders.*, users.role as user_role')
		@not_paid_rial = PaymentOrder.filtered_orders('wait for payment', 'rial', selected_month).joins(:user)
                    .select('payment_orders.*, users.role as user_role')
		@not_paid_dirham = PaymentOrder.filtered_orders('wait for payment', 'dirham', selected_month).joins(:user)
                    .select('payment_orders.*, users.role as user_role')
		@paid_dollar = PaymentOrder.paid_by_currency(selected_month, 'dollar').joins(:user)
                    .select('payment_orders.*, users.role as user_role')
		@paid_rial = PaymentOrder.paid_by_currency(selected_month, 'rial').joins(:user)
                    .select('payment_orders.*, users.role as user_role')
		@paid_dirham = PaymentOrder.paid_by_currency(selected_month, 'dirham').joins(:user)
                    .select('payment_orders.*, users.role as user_role')
		@sum_not_paid_dollar = @not_paid_dollar.sum(:amount)
		@sum_not_paid_rial = @not_paid_rial.sum(:amount)
		@sum_not_paid_dirham = @not_paid_dirham.sum(:amount)
		@sum_paid_dollar = @paid_dollar.sum(:amount)
		@sum_paid_rial = @paid_rial.sum(:amount)
		@sum_paid_dirham = @paid_dirham.sum(:amount)






	end





	def create
		

		@payment_order = current_user.payment_orders.new(payment_order_params)
		@payment_order.user = current_user
		respond_to do |format|
			if @payment_order.save
				if !current_user.is_manager
					users_to_notify = User.where(role: current_user.role, is_manager: true)
					users_to_notify.each do |user|
						user.notifications.create(
							payment_id: params[:id],
							message: 'Confirmation required for Payment order',
							is_read: false,
							link_to_action: payment_order_path(@payment_order)
							)
					end

				end
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
			:receipt,
			:delivery_confirm,
			:ceo_confirmed_at,
			:coo_confirmed_at,
			:department_confirmed_at,
			:accounting_confirmed_at,
			:delivered_at,
			:reject_by,
			:rejected_at
			)
	end


end