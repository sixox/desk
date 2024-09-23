class ProjectsController < ApplicationController
	
  before_action :authenticate_user!, except: [:project_login, :authenticate, :time_line]
	before_action :set_project, only: %i[ show edit update destroy allocate card time_line update_timeline turnover] 
  before_action :verify_project_access, only: :time_line
  before_action :set_timeline, only: %i[ show time_line ]



	def show
		@pi = @project.pi if @project.pi
		@cis = @project.cis if @project.cis
		@bookings = @project.bookings if @project.bookings
		@allocates = @project.ballance_projects
		filtered_payment_orders = @project.payment_orders
		@payment_orders_with_status_paid_dollar = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'dollar')
		@payment_orders_with_status_paid_dirham = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'dirham')
		@payment_orders_with_status_paid_rial = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'rial')
		@sum_paid_dollar = @payment_orders_with_status_paid_dollar.sum(:amount)
		@sum_paid_dirham = @payment_orders_with_status_paid_dirham.sum(:amount)
		@sum_paid_rial = @payment_orders_with_status_paid_rial.sum(:amount)
		@payment_orders_with_status_not_paid = filtered_payment_orders.where.not(status: ['wait for delivery', 'delivered'])
		@remains = @project.remaining_quantity



	end

	def index
		@q = Project.ransack(params[:q])
	  @projects = @q.result.includes(:pi, :cis, :bookings, :swifts, ballance_projects: :ballance).order(number: :desc)
	end

	def new	
		@project = Project.new
	end

	def create
		@project = Project.new(project_params)
		respond_to do |format|
			if @project.save
				format.html { redirect_to project_url(@project), notice: "Project was successfully created." }
				format.json { render :show, status: :created, location: @project }
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'projects/form', modal_title: 'Add new Project' })}
			end
		end
	end

	def edit
	end

	def update
		if @project.update(project_params)
			redirect_to project_path(@project), notice: "Project Edited Successfully"
		else
			redirect_to project_path(@project), alert: "Project Edited not Done"
		end
	end

	def destroy
	end

	def allocate
	end

	def list
	  @q = Project.ransack(params[:q])
	  @projects = @q.result.includes(:cis).joins(:pi).order(created_at: :desc)
	end


	def card
	end

	def project_login
	end

  def authenticate
    @project = Project.joins(:pi).find_by(pis: { number: params[:unique_number] })

    if @project&.authenticate(params[:password])
      session[:project_id] = @project.id
      redirect_to time_line_project_path(@project), notice: "Entered Project Page Successfully"
    else
      flash[:alert] = "Invalid PI number or password"
      redirect_to project_login_path
    end
  end

  def time_line
  end

  def update_timeline
  	@pi = @project.pi
  end

	
def turnover
  @all_payments_done = @project.bookings.all? { |booking| booking.payment_done }
  balance_projects = @project.ballance_projects
  @advance_payments = {}
  @balance_payments = {}

  # Gather advance payments
  balance_projects.each do |balance_project|
    advance_orders = PaymentOrder.where(project: nil, ballance: balance_project.ballance)
    advance_orders.each do |payment_order|
      amount = payment_order.currency == "dirham" ? payment_order.amount.to_i : payment_order.amount.to_i * 3.67
      amount *= (@project.cis.sum(:net_weight) / balance_project.ballance.spi.quantity)
      @advance_payments[payment_order.id] = { amount: amount.to_i, date: payment_order.ceo_confirmed_at }
    end
  end

  # Gather balance payments
  balance_projects.each do |balance_project|
    balance_orders = PaymentOrder.where(project: @project, ballance: balance_project.ballance)
    balance_orders.each do |payment_order|
      amount = payment_order.currency == "dirham" ? payment_order.amount.to_i : payment_order.amount.to_i * 3.67
      @balance_payments[payment_order.id] = { amount: amount.to_i, date: payment_order.ceo_confirmed_at }
    end
  end

  @received_swifts = {}

  @project.total_swifts.each do |swift|
    next unless swift.confirmed

    amount = swift.currency == "dirham" ? swift.amount.to_i : swift.amount.to_i * 3.67
    @received_swifts[swift.id] = { amount: amount.to_f, date: swift.created_at }
  end

  # Sort @received_swifts by date
  @received_swifts = @received_swifts.sort_by { |swift_id, swift_data| swift_data[:date] }.to_h

  # Combine advance and balance payments into a single hash
  @payments = @advance_payments.merge(@balance_payments).sort_by { |payment_id, payment_data| payment_data[:date] }.to_h

  # Calculate return days and profit
  @final_days, @profit = calculate_return_days_and_profit(@payments, @received_swifts)
end











	private

	def set_timeline
		@project = Project.includes(:pi, :cis, :bookings, :swifts).find(params[:id])
    @latest_booking = @project.bookings&.max_by(&:updated_at)
    @any_bl_draft_attached = @project.bookings&.any? { |booking| booking.bl_draft.attached? }
    @all_bookings_done = @project.bookings.all? { |booking| booking.payment_done }
    filtered_swifts = @project.swifts.where.not(advance: true)
    # Collect Swifts from each Ci associated with the project
    cis_swifts = @project.cis.map(&:swift).compact

    # Merge the two arrays
    @balance_swifts = (filtered_swifts + cis_swifts).uniq
    @total_balance_swift_amount = @balance_swifts.sum(&:amount)
    @advance_swifts = @project.swifts&.where(advance: true)
	end

	def set_project
		@project = Project.find(params[:id])
	end

  def verify_project_access
  	return if user_signed_in? 
    unless session[:project_id] == @project.id
      flash[:alert] = "Unauthorized access to the project"
      redirect_to project_login_path
    end
  end

	def project_params
		params.require(:project).permit(:number, :status, :name, :new_destination, :shipping, :exchange, :supplier_prepaid, :delivery_failure, :supplier_credits, :third_person, :custom_clearance, :logistic, :quality, :risk, :new_customer, :impact, :likelihood, :selected_risk, :password, :password_confirmation, :started )
	end

	def calculate_return_days_and_profit
	  final = 0
	  total_payments = @payments.sum { |payment| payment[:amount] }
	  remaining_payment_amount = 0
	  swift_index = 0

	  # Sort payments and swifts by date
	  sorted_payments = @payments.sort_by { |payment| payment[:date] }
	  sorted_swifts = @received_swifts.sort_by { |_swift_id, swift_data| swift_data[:date] }.to_h

	  # Traverse through payments and swifts
	  sorted_payments.each do |payment|
	    while payment[:amount] > 0 && swift_index < sorted_swifts.size
	      swift_id, swift_data = sorted_swifts.to_a[swift_index]
	      swift_date = swift_data[:date].to_date
	      payment_date = payment[:date].to_date
	      days_between = (swift_date - payment_date).to_i.abs # Ensure days_between is always positive

	      if payment[:amount] >= swift_data[:amount]
	        # Swift fully covers the payment
	        final += swift_data[:amount] * days_between
	        payment[:amount] -= swift_data[:amount]
	        swift_index += 1 # Move to the next swift
	      else
	        # Swift partially covers the payment
	        final += payment[:amount] * days_between
	        swift_data[:amount] -= payment[:amount]
	        payment[:amount] = 0 # Move to the next payment
	      end
	    end

	    # Any remaining amount in payments is considered profit
	    remaining_payment_amount += payment[:amount] if payment[:amount] > 0
	  end

	  # Calculate final return days and profit
	  return_days = total_payments > 0 ? final / total_payments : 0
	  profit = remaining_payment_amount

	  { return_days: return_days, profit: profit }
	end









end
