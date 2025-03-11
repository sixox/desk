class PaymentOrdersController < ApplicationController
	before_action :authenticate_user!
	before_action :set_payment_order, only: %i[ show edit reject confirm update destroy hamed_confirm toggle_announce]
	before_action :set_form_items, only: %i[ new edit create ] 
	before_action :set_access_to_secret, only: %i[ show index not_paid not_confirmed finished rejected pending not_delivered mine confirmable reports]
	



  def export
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date]).end_of_day
			payment_orders = PaymentOrder.where(created_at: start_date..end_date)
			payment_orders = payment_orders.where.not(mahramane: true) unless current_user.is_manager

      if payment_orders.exists?
          csv_data = payment_orders.to_csv

				  send_data csv_data,
            filename: "payment_orders-#{start_date}-to-#{end_date}.csv",
            type: 'text/csv'
      else
        redirect_to payment_orders_path, alert: "No payment orders found for the selected date range."
      end
    else
      redirect_to payment_orders_path, alert: "Please provide both start and end dates."
    end
  end

	def show
	end

def index
  @in_page = "index"
  cu = current_user
  
  # Initialize Ransack search object with parameters from the view
  @q = PaymentOrder.ransack(params[:q])
  
  # Check user roles and filter the results accordingly
  if (current_user.is_manager && current_user.procurement?) || (current_user.admin? || current_user.accounting? || current_user.ceo? || current_user.cob?)
    @payment_orders = @q.result.order(created_at: :desc).page(params[:page]).per(6)
  else
    # If the user is not a manager, admin, etc., apply specific filtering
    @payment_orders = @q.result
                        .filtered_by_role(current_user)
                        .where.not(user_id: 9)
                        .order(created_at: :desc)
                        .page(params[:page])
                        .per(6)
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
		elsif current_user.accounting?
			ro = "Accounting"
		elsif current_user.cob?
			ro = "COB"
		else
			ro = "Manager"
		end
		@payment_order.reject_by = ro
		
		@payment_order.rejected_at = Time.now
		respond_to do |format|
			if @payment_order.save
				format.html { redirect_to payment_orders_path, notice: 'Payment order rejected successfully' }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @payment.errors, status: :unprocessable_entity }

			end
		end

	end

	def hamed_confirm
		@payment_order.hamed_confirm = true
		@payment_order.hamed_confirmed_at = Time.now
		respond_to do |format|
			if @payment_order.save
				format.html { redirect_to payment_orders_path, notice: 'Payment order confirmed successfully' }
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
			if @payment_order.user.ceo?
				@payment_order.department_confirm = true
				@payment_order.department_confirmed_at = Time.now
			end


		elsif current_user.cob?
			@payment_order.cob_confirm = true
			@payment_order.cob_confirmed_at = Time.now
			if @payment_order.user.cob?
				@payment_order.department_confirm = true
				@payment_order.department_confirmed_at = Time.now
			end	
		elsif current_user.procurement?
			@payment_order.coo_confirm = true
			@payment_order.coo_confirmed_at = Time.now
			if @payment_order.user.procurement?
				@payment_order.department_confirm = true
				@payment_order.department_confirmed_at = Time.now
			end




		elsif current_user.accounting?
			@payment_order.accounting_confirm = true
			@payment_order.accounting_confirmed_at = Time.now
			if current_user.id == 29
				@payment_order.shaghayegh_confirm = true
			end
			if @payment_order.user.accounting?
				@payment_order.department_confirm = true
				@payment_order.department_confirmed_at = Time.now
			end



		elsif current_user.is_manager && !current_user.procurement?
			@payment_order.department_confirm = true
			@payment_order.department_confirmed_at = Time.now


		end
		
		respond_to do |format|
			if @payment_order.save
				format.html { redirect_to payment_orders_path, notice: 'Payment order confirmed successfully' }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @payment.errors, status: :unprocessable_entity }

			end
		end
	end

	def delivered

		@payment_order = PaymentOrder.find(params[:id])
		@payment_order.skip_coo_confirmation_requirement = true

		@payment_order.delivered_at = Time.now
		respond_to do |format|
			if @payment_order.update(delivery_confirm: true)
				format.html { redirect_to payment_orders_path, notice: 'Payment order was successfully updated' }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @payment.errors, status: :unprocessable_entity }
			end

		end
	end

	def not_paid
	  @in_page = "notp"
	  cu = current_user

	  # Initialize Ransack search object
	  @q = PaymentOrder.ransack(params[:q])
	  
	  if (cu.is_manager && cu.procurement?) || cu.admin? || cu.accounting? || cu.ceo? ||cu.cob?
	    @payment_orders = @q.result
	                        .where(status: 'wait for payment')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  else
	    @payment_orders = @q.result
	                        .joins(:user)
	                        .where(users: { role: cu.role })
	                        .where(status: 'wait for payment')
	                        .where.not(user_id: 9)
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  end
	  render 'index'
	end

	def not_confirmed
	  @in_page = "not confirmed"
	  cu = current_user

	  # Initialize Ransack search object
	  @q = PaymentOrder.ransack(params[:q])

	  base_query = @q.result.where(status: 'wait for confirm', reject_by: nil).order(created_at: :desc)

	  if (cu.is_manager && cu.procurement?) || cu.admin? || cu.accounting? || cu.ceo? || cu.cob?
	    @payment_orders = base_query.page(params[:page]).per(6)
	  else
	    @payment_orders = base_query.joins(:user).where(users: { role: cu.role }).where.not(user_id: 9).page(params[:page]).per(6)
	  end
	  render 'index'
	end

	def finished
	  @in_page = "finished"
	  cu = current_user

	  # Initialize Ransack search object
	  @q = PaymentOrder.ransack(params[:q])

	  if (cu.is_manager && cu.procurement?) || cu.admin? || cu.accounting? || cu.cob? || cu.ceo?
	    @payment_orders = @q.result
	                        .where(status: 'delivered')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  else
	    @payment_orders = @q.result
	                        .joins(:user)
	                        .where(users: { role: cu.role })
	                        .where.not(user_id: 9)
	                        .where(status: 'delivered')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  end
	  render 'index'
	end

	def rejected
	  @in_page = "rejected"
	  cu = current_user

	  # Initialize Ransack search object
	  @q = PaymentOrder.ransack(params[:q])

	  if (cu.is_manager && cu.procurement?) || cu.admin? || cu.cob? || cu.accounting? || cu.ceo?
	    @payment_orders = @q.result
	                        .where(status: 'rejected')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  else
	    @payment_orders = @q.result
	                        .joins(:user)
	                        .where(users: { role: cu.role })
	                        .where.not(user_id: 9)
	                        .where(status: 'rejected')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  end
	  render 'index'
	end

	def pending
	  @in_page = "pending"
	  cu = current_user

	  # Initialize Ransack search object
	  @q = PaymentOrder.ransack(params[:q])

	  if (cu.is_manager && cu.procurement?) || cu.admin? || cu.cob? || cu.accounting? || cu.ceo?
	    @payment_orders = @q.result
	                        .where.not(status: 'delivered')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  else
	    @payment_orders = @q.result
	                        .joins(:user)
	                        .where(users: { role: cu.role })
	                        .where.not(user_id: 9)
	                        .where.not(status: 'delivered')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  end
	  render 'index'
	end

	def not_delivered
	  @in_page = "notd"
	  cu = current_user

	  # Initialize Ransack search object
	  @q = PaymentOrder.ransack(params[:q])

	  if (cu.is_manager && cu.procurement?) || cu.admin? || cu.cob? || cu.accounting? || cu.ceo?
	    @payment_orders = @q.result
	                        .where(status: 'wait for delivery')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  else
	    @payment_orders = @q.result
	                        .joins(:user)
	                        .where(users: { role: cu.role })
	                        .where.not(user_id: 9)
	                        .where(status: 'wait for delivery')
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  end
	  render 'index'
	end

	def mine
	  @in_page = "mine"
	  cu = current_user
	  status = params[:status]

	  # Initialize Ransack search object
	  @q = cu.payment_orders.ransack(params[:q])

	  if status.present?
	    @payment_orders = @q.result
	                        .by_status(status)
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  else
	    @payment_orders = @q.result
	                        .order(created_at: :desc)
	                        .page(params[:page])
	                        .per(6)
	  end
	  render 'index'
	end

	def confirmable
	  @in_page = "confirmable"
	  cu = current_user

	  if cu.accounting?
			@release_requests = ReleaseRequest.where(confirmed: [false, nil])
	  end

	  # Initialize Ransack search object
	  @q = PaymentOrder.ransack(params[:q])

	  if cu.is_manager || cu.id == 29
	    if cu.ceo?
	      @payment_orders = @q.result
	                          .not_confirmed_by_ceo_but_by_coo_and_accounting
	                          .order(created_at: :desc)
	    elsif cu.cob?
	    	@payment_orders = @q.result
	                          .not_confirmed_by_cob_but_by_ceo_and_accounting
	                          .order(created_at: :desc)

	    elsif cu.procurement?
	      @payment_orders = @q.result
	                          .not_confirmed_by_coo
	                          .order(created_at: :desc)
	    elsif cu.accounting?
	      accounting_pos = PaymentOrder.filtered_by_role_and_dep_confirm(cu)
	      @payment_orders = @q.result
	                          .not_confirmed_by_accounting
	                          .order(created_at: :desc)
	      @payment_orders += accounting_pos
	      @payment_orders.sort_by!(&:created_at).reverse!
	    else
	      @payment_orders = PaymentOrder.filtered_by_role_and_dep_confirm(cu)
	                          .order(created_at: :desc)
	    end

	    @payment_orders = Kaminari.paginate_array(@payment_orders).page(params[:page]).per(6)
	  end

	  if cu.ceo?
	    @transfers = Transfer.where(confirmed: [nil, false], rejected: [nil, false], coo_confirmed: [true])
	  end

	  if cu.is_manager && cu.procurement?
	    @transfers = Transfer.where(confirmed: [nil, false], rejected: [nil, false], coo_confirmed: [nil, false])
	  end

	  render 'index'
	end


	def reports
		if ActiveRecord::Base.connection.adapter_name.downcase == 'sqlite'
			@distinct_years = PaymentOrder.distinct.pluck(Arel.sql("strftime('%Y', created_at)")).map(&:to_i)
			@distinct_months = PaymentOrder.distinct.pluck(Arel.sql("strftime('%m', created_at)")).map(&:to_i)
		else
			@distinct_years = PaymentOrder.distinct.pluck(Arel.sql("DATE_FORMAT(created_at, '%Y')")).map(&:to_i)
			@distinct_months = PaymentOrder.distinct.pluck(Arel.sql("DATE_FORMAT(created_at, '%m')")).map(&:to_i)
		end


		selected_date = parse_selected_date(params.dig(:selected_date, :year), params.dig(:selected_date, :month))
		@selected_year = selected_date&.year || Date.current.year
		@selected_month = selected_date&.month || Date.current.month

		@not_paid_dollar = PaymentOrder.filtered_orders('wait for payment', 'dollar', selected_date).joins(:user)
		.select('payment_orders.*, users.role as user_role')
		@not_paid_rial = PaymentOrder.filtered_orders('wait for payment', 'rial', selected_date).joins(:user)
		.select('payment_orders.*, users.role as user_role')
		@not_paid_dirham = PaymentOrder.filtered_orders('wait for payment', 'dirham', selected_date).joins(:user)
		.select('payment_orders.*, users.role as user_role')
		@paid_dollar = PaymentOrder.paid_by_currency(selected_date, 'dollar').joins(:user)
		.select('payment_orders.*, users.role as user_role')
		@paid_rial = PaymentOrder.paid_by_currency(selected_date, 'rial').joins(:user)
		.select('payment_orders.*, users.role as user_role')
		@paid_dirham = PaymentOrder.paid_by_currency(selected_date, 'dirham').joins(:user)
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
		# respond_to do |format|
		# 	if @payment_order.save
		# 		if !current_user.is_manager
		# 			users_to_notify = User.where(role: current_user.role, is_manager: true)
		# 			users_to_notify.each do |user|
		# 				user.notifications.create(
		# 					payment_id: params[:id],
		# 					message: 'Confirmation required for Payment order',
		# 					is_read: false,
		# 					link_to_action: payment_order_path(@payment_order)
		# 					)
		# 			end

		# 		end
		# 		format.turbo_stream { render turbo_stream: turbo_stream.prepend('payment_order_items', partial: 'payment_orders/payment_order', locals: { payment_order: @payment_order }) }
		# 	else
		# 		format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'payment_orders/form', modal_title: 'Add payment_order' })}
		# 	end
		# end
		respond_to do |format|
		if @payment_order.save
		    
		    format.turbo_stream do
		      render turbo_stream: [
		        turbo_stream.prepend('payment_order_items', partial: 'payment_orders/payment_order', locals: { payment_order: @payment_order }),
		        turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'Payment order was successfully created.' })
		      ]
		    end
		  else
		    format.turbo_stream do 
		      render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'payment_orders/form', modal_title: 'Add payment_order' })
		    end
		  end
		end

	end

	def update

		if params[:payment_order].key?(:receipt) || params[:payment_order].key?('receipt')
			@payment_order.assign_attributes(payment_order_params)
		    @bank = @payment_order.bank
		    current_balance = @bank.account_balance.to_i
		  
			if @payment_order.currency == @bank.currency
		      # Scenario 1: Currencies match, proceed normally
		      if @payment_order.exchange_amount.present?
		      	new_amount = @bank.account_balance - @payment_order.exchange_amount
		      	withdrawal_amount = @payment_order.exchange_amount.to_i
		      else
		      	new_amount = @bank.account_balance - @payment_order.amount.to_f
		      	withdrawal_amount = @payment_order.amount.to_i
		      end
			elsif @payment_order.currency != @bank.currency && (@payment_order.exchange_amount.present? || params[:payment_order][:exchange_amount].present?)
		      # Scenario 2: Currencies don't match, but exchange_amount is provided
		      if @payment_order.valid?
		        @payment_order.save
		        new_amount = @bank.account_balance - @payment_order.exchange_amount.to_f
		        withdrawal_amount = @payment_order.exchange_amount.to_i
		      else
		        render :show and return
		      end
		    else
		      # Scenario 3: Currencies don't match and no exchange_amount is provided
		      @payment_order.errors.add(:currency, "does not match with the bank's currency and no exchange amount provided")
		      @p_mas = "does not match with the bank's currency and no exchange amount provided"
		      render :show and return
		    end
		    if @bank.update(account_balance: new_amount)
		      transaction = @payment_order.transactions.create(
			      withdrawal_amount: withdrawal_amount , 
			      bank: @bank,
			      balance_before_transaction: current_balance.to_i,
			      balance_after_transaction: new_amount.to_i
			    )
		    else
		      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'payment_orders/form', modal_title: 'Edit payment_order ' })}
		      # Handle error
		    end
		end

		respond_to do |format|
			if @payment_order.update(payment_order_params)
	      redirect_to @payment_order, notice: 'Payment order was successfully updated.'
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'payment_orders/form', modal_title: 'Edit payment_order ' })}
			end
		end
	end



	def toggle_announce
	    @payment_order.update(announce: !@payment_order.announce)
	    
	     respond_to do |format|
		    format.html { redirect_back fallback_location: @payment_order, notice: "Announce status updated." }
		    format.turbo_stream # For Turbo updates (if using Turbo)
		  end
	end

	def destroy
		respond_to do |format|
			@payment_order.destroy
			format.turbo_stream { render turbo_stream: turbo_stream.remove("payment_order_item_#{@payment_order.id}") }
		end
	end




	private

	def parse_selected_date(selected_year_param, selected_month_param)
		if selected_year_param.present? && selected_month_param.present?
			selected_year = selected_year_param.to_i
			selected_month = selected_month_param.to_i
			Date.new(selected_year, selected_month)
		else
	    nil # Handle the case when no year and month are selected
	  end
	end


	def set_payment_order
		@payment_order = PaymentOrder.find(params[:id])	
		@banks = Bank.all

	end

	def set_form_items
		@ballances = Ballance.all.reverse
		@projects = Project.all.reverse
		@bookings = Booking.all.reverse
		@spis = Spi.all.reverse
		@scis = Sci.all.reverse
		@banks = Bank.all


	end

	def set_access_to_secret
		if current_user.ceo? || current_user.cob? || current_user.admin? || (current_user.accounting? && current_user.is_manager )
			@access_to_secret = true
		end
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
			:rejected_at,
			:bank_id,
			:mahramane
			)
	end


end