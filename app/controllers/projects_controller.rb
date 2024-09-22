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
	  @advance_payments = []
	  @balance_payments = []

	  balance_projects.each do |balance_project|
	    # Adjust advance payment based on project.pi.quantity ratio
	    adjusted_advance_payments = PaymentOrder.where(project: nil, ballance: balance_project.ballance).map do |payment|
	      adjusted_amount = payment.amount * @project.pi.quantity / balance_project.ballance.spi.quantity
	      payment.attributes.merge(amount: adjusted_amount) # Adjust the amount in the hash
	    end

	    @advance_payments.push(*adjusted_advance_payments)
	  end

	  balance_projects.each do |balance_project|
	    @balance_payments.push(*PaymentOrder.where(project: @project, ballance: balance_project.ballance))
	  end

	  # Combine payments and sort them by confirmation date
	  payments = (@advance_payments + @balance_payments).sort_by { |p| p["ceo_confirmed_at"] }
	  swifts = @project.total_swifts.sort_by(&:created_at)

	  # Initialize a hash to store payment date and amount
	  payment_hash = payments.map do |p|
	    amount = p["currency"] == "dolar" ? convert_amount(p["amount"]) : p["amount"]
	    { amount: amount, date: p["ceo_confirmed_at"] }
	  end

	  swift_hash = swifts.map do |s|
	    amount = s.currency == "dolar" ? convert_amount(s.amount) : s.amount
	    { amount: amount, date: s.created_at }
	  end

	  @total_payments = payment_hash.sum { |p| p[:amount] }
	  @total_swifts = swift_hash.sum { |s| s[:amount] }

	  # Calculate the profit (total swifts received - total payments made)
	  @profit = @total_swifts - @total_payments

	  total_weighted_days = 0
	  total_swift_amount = 0

	  swift_hash.each do |swift|
	    swift_amount = swift[:amount]
	    swift_date = swift[:date]

	    # Continue applying payments until the swift is covered
	    while swift_amount > 0 && !payment_hash.empty?
	      payment = payment_hash.first
	      payment_amount = payment[:amount]
	      payment_date = payment[:date]

	      # Amount to apply from this payment
	      apply_amount = [swift_amount, payment_amount].min
	      days_outstanding = (swift_date - payment_date).to_i

	      # Calculate weighted days (amount * days outstanding)
	      total_weighted_days += apply_amount * days_outstanding
	      total_swift_amount += apply_amount

	      # Update the payment amount and swift amount
	      payment[:amount] -= apply_amount
	      swift_amount -= apply_amount

	      # Remove the payment if it's fully applied
	      payment_hash.shift if payment[:amount] <= 0
	    end
	  end

	  # Calculate DSO
	  @dso = total_weighted_days.to_f / total_swift_amount
	  @dso = @dso.round(2)
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




end
