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
	  @projects = @q.result.includes(:pi, :cis, :bookings, :swifts, ballance_projects: :ballance).order(created_at: :desc)
    @projects = @projects.page(params[:page]).per(18)

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
    if params[:release_permission].present?
      @project.password ||= "@min2542026@JDJDJDjdjdhfg^@&" if params[:release_permission] == "true"
      @project.release_permission_date = Time.now
      if @project.update(release_permission: params[:release_permission] == "true")
        redirect_to project_path(@project), notice: "Release Permission #{params[:release_permission] == "true" ? "Granted" : "Revoked"} Successfully"
      else
        redirect_to project_path(@project), alert: "Failed to Update Release Permission"
      end
    else
      if @project.update(project_params)
        redirect_to project_path(@project), notice: "Project Edited Successfully"
      else
        redirect_to project_path(@project), alert: "Project Editing Failed"
      end
    end
  end



	def destroy
	end

	def allocate
	end

  def list
    @q = Project.ransack(params[:q])
    @projects = @q.result
                  .includes(
                    :pi,
                    :cis,
                    :bookings,
                    :swifts,
                    ballance_projects: { ballance: :supplier }
                  )
                  .order(created_at: :desc)
                  .page(params[:page])
                  .per(300)
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
        @advance_payments[payment_order.id] = { amount: amount.to_i, date: payment_order.cob_confirmed_at }
      end
    end

    # Gather balance payments
    balance_projects.each do |balance_project|
      balance_orders = PaymentOrder.where(project: @project, ballance: balance_project.ballance)
      balance_orders.each do |payment_order|
        amount = payment_order.currency == "dirham" ? payment_order.amount.to_i : payment_order.amount.to_i * 3.67
        @balance_payments[payment_order.id] = { amount: amount.to_i, date: payment_order.cob_confirmed_at }
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
    calculate_return_days_and_profit
  end


  def export_csv
    respond_to do |format|
      format.csv { send_data Project.to_csv, filename: "projects-#{Date.today}.csv" }
    end
  end


  def turnovers
    # Base scope with eager-loading (same as you had)
    base = Project
             .includes(:pi, :bookings, :swifts)
             .includes(cis: :swift)
             .includes(ballance_projects: :ballance)
             .order(created_at: :desc)

    # --- Optional Customer filter ----------------------------------------
    if params[:customer_id].present?
      base = base.joins(:pi).where(pis: { customer_id: params[:customer_id] })
    end

    # For the dropdown
    @customers = Customer.order(:nickname) rescue Customer.order(:id)
    # ---------------------------------------------------------------------

    # Eligible projects: same rule as single-project turnover view
    eligible = base.select do |p|
      (p.bookings.present? && p.bookings.all?(&:payment_done)) || p.pi&.packing_type == "bulk"
    end

    # Paginate
    @projects_page = Kaminari.paginate_array(eligible).page(params[:page]).per(30)

    # Build rows
    @rows = @projects_page.map do |project|
      balance_projects = project.ballance_projects

      # Visible payments table (advance + balance) — keep rials visible but we will skip them from calculations below
      display_payments = []
      balance_projects.each do |bp|
        display_payments.concat(PaymentOrder.where(project: nil,  ballance: bp.ballance))
        display_payments.concat(PaymentOrder.where(project: project, ballance: bp.ballance))
      end
      display_payments.sort_by!(&:created_at)

      # DSO inputs (safe dates + numeric guards)
      advance_payments = {}
      balance_payments = {}

      total_net_weight = project.cis.sum(:net_weight).to_f

      balance_projects.each do |bp|
        spi = bp.ballance&.spi
        spi_qty = spi&.quantity.to_f
        factor = (spi_qty.positive? ? (total_net_weight / spi_qty) : 0.0)

        PaymentOrder.where(project: nil, ballance: bp.ballance).find_each do |po|
          next if po.currency.to_s.downcase == "rial"   # <-- SKIP rials for calculations
          base_amount = po.amount.to_f
          amount = (po.currency == "dirham" ? base_amount : base_amount * 3.67)
          amount *= factor
          date = po.cob_confirmed_at || po.created_at
          advance_payments[po.id] = { amount: amount, date: date }
        end
      end

      balance_projects.each do |bp|
        PaymentOrder.where(project: project, ballance: bp.ballance).find_each do |po|
          next if po.currency.to_s.downcase == "rial"   # <-- SKIP rials for calculations
          base_amount = po.amount.to_f
          amount = (po.currency == "dirham" ? base_amount : base_amount * 3.67)
          date = po.cob_confirmed_at || po.created_at
          balance_payments[po.id] = { amount: amount, date: date }
        end
      end

      # swifts (received)
      received_swifts = {}
      project.total_swifts.each do |swift|
        next unless swift.confirmed
        base_amount = swift.amount.to_f
        amt = (swift.currency == "dirham" ? base_amount : base_amount * 3.67)
        date = swift.created_at
        received_swifts[swift.id] = { amount: amt, date: date }
      end

      # Sort safely (dates are non-nil because of fallback above)
      received_swifts = received_swifts.sort_by { |_id, h| h[:date] }.to_h
      payments_hash   = advance_payments.merge(balance_payments).sort_by { |_id, h| h[:date] }.to_h

      metrics = compute_return_days_and_profit_for_list(payments_hash, received_swifts)

      OpenStruct.new(
        project:        project,
        dso_days:       metrics[:return_days],
        profit:         metrics[:profit],
        total_payments: metrics[:total_payments],
        payments_table: display_payments,
        swifts_table:   project.total_swifts
      )
    end

    # --- New: if customer filter, compute average DSO for the listed rows (ignore nils) ---
    if params[:customer_id].present?
      dso_values = @rows.map(&:dso_days).compact
      @customer_average_dso = dso_values.any? ? (dso_values.sum.to_f / dso_values.size) : nil
    else
      @customer_average_dso = nil
    end
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
		params.require(:project).permit(:number, :status, :name, :new_destination, :shipping, :exchange, :supplier_prepaid, :delivery_failure, :supplier_credits, :third_person, :custom_clearance, :logistic, :quality, :risk, :new_customer, :impact, :likelihood, :selected_risk, :password, :password_confirmation, :started, :release_permission )
	end

  def compute_return_days_and_profit_for_list(payments_hash, received_swifts_hash)
    final = 0.0
    total_payments = payments_hash.sum { |_id, p| p[:amount].to_f }

    sorted_payments = payments_hash.sort_by { |_id, p| p[:date] }
    sorted_swifts   = received_swifts_hash.sort_by { |_id, s| s[:date] }

    p_i = 0
    s_i = 0
    # We duplicate the hash so we can mutate amounts safely
    p_copy = sorted_payments.map { |id, h| [id, { amount: h[:amount].to_f, date: h[:date] }] }
    s_copy = sorted_swifts.map   { |id, h| [id, { amount: h[:amount].to_f, date: h[:date] }] }

    while p_i < p_copy.size && s_i < s_copy.size
      p_amt = p_copy[p_i][1][:amount]
      s_amt = s_copy[s_i][1][:amount]
      p_date = p_copy[p_i][1][:date].to_datetime
      s_date = s_copy[s_i][1][:date].to_datetime

      days_between = (s_date - p_date).to_i.abs

      if p_amt >= s_amt
        final += s_amt * days_between
        p_copy[p_i][1][:amount] = p_amt - s_amt
        s_i += 1
      else
        final += p_amt * days_between
        s_copy[s_i][1][:amount] = s_amt - p_amt
        p_i += 1
      end
    end

    profit      = total_payments - final
    return_days = total_payments > 0 ? (final / total_payments) : 0

    { final: final, profit: profit, return_days: return_days, total_payments: total_payments }
  end

def calculate_return_days_and_profit
  @final = 0
  @total_payments = @payments.sum { |_id, payment| payment[:amount] }
  @remaining_payment_amount = 0

  # Sort payments and received swifts
  sorted_payments = @payments.sort_by { |_id, payment_data| payment_data[:date] }
  sorted_swifts = @received_swifts.sort_by { |_id, swift_data| swift_data[:date] }

  payment_index = 0
  swift_index = 0

  while payment_index < sorted_payments.size && swift_index < sorted_swifts.size
    payment = sorted_payments[payment_index][1]  # Get the payment data
    swift = sorted_swifts[swift_index][1]        # Get the swift data

    # Convert dates to DateTime objects to ensure proper subtraction
    payment_date = payment[:date].to_datetime
    swift_date = swift[:date].to_datetime

    days_between = (swift_date - payment_date).to_i.abs

    # Log current values for debugging
    Rails.logger.debug "Payment Amount: #{payment[:amount]}, Swift Amount: #{swift[:amount]}, Days Between: #{days_between}, Current Final: #{@final}"

    if payment[:amount] >= swift[:amount]
      @final += swift[:amount] * days_between
      payment[:amount] -= swift[:amount]
      Rails.logger.debug "Updated Final: #{@final}, Remaining Payment Amount: #{payment[:amount]}, Moving to next Swift"
      swift_index += 1
    else
      @final += payment[:amount] * days_between
      swift[:amount] -= payment[:amount]
      Rails.logger.debug "Updated Final: #{@final}, Remaining Swift Amount: #{swift[:amount]}, Moving to next Payment"
      payment_index += 1
    end
  end

  # Calculate profit
  @profit = @total_payments - @final
  @return_days = @total_payments > 0 ? @final / @total_payments : 0

  # Log final results
  Rails.logger.debug "Total Payments: #{@total_payments}, Final: #{@final}, Profit: #{@profit}, Return Days: #{@return_days}"
end
end
