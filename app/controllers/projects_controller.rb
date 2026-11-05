class ProjectsController < ApplicationController
	
  before_action :authenticate_user!, except: [:project_login, :authenticate, :time_line]
	before_action :set_project, only: %i[ show edit update destroy allocate card time_line update_timeline turnover] 
  before_action :verify_project_access, only: :time_line
  before_action :set_timeline, only: %i[ show time_line ]



	def show
		
	end

	def index
    @q = Project.ransack(params[:q])

    projects = @q.result
      .includes(
        { pi: :customer },
        { cis: [:pi, :swift] },
        :bookings,
        { swifts: :bank },
        {
          ballance_projects: {
            ballance: [:supplier, :spi]
          }
        }
      )

    case params[:stage].to_s
    when "sales_open"
      projects = projects.where(sales_done: [nil, false])

    when "logistics_open"
      projects = projects.where(logistics_done: [nil, false])

    when "completed"
      projects = projects.where(
        sales_done: true,
        logistics_done: true
      )

    when "at_risk"
      projects = projects.where("projects.risk >= ?", 26)

    when "without_pi"
      projects = projects
        .left_outer_joins(:pi)
        .where(pis: { id: nil })
    end

    @project_stats = {
      total: Project.count,

      sales_open: Project
        .where(sales_done: [nil, false])
        .count,

      logistics_open: Project
        .where(logistics_done: [nil, false])
        .count,

      high_risk: Project
        .where("projects.risk >= ?", 26)
        .count
    }

    @projects = projects
      .order(updated_at: :desc)
      .page(params[:page])
      .per(18)

    @project_total_count = @projects.total_count
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
        render :show, status: :unprocessable_entity
      end
    end
  end


  def finish_sales
    @project = Project.find(params[:id])

    authorize_sales! # optional if you already have authorization logic

    @project.finish_sales!

    redirect_to @project, notice: "Sales marked as finished."
  end

  def finish_logistics
    @project = Project.find(params[:id])

    authorize_logistics!

    @project.finish_logistics!

    redirect_to @project, notice: "Logistics marked as finished and bookings settled."
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



  def authorize_sales!
    head :forbidden unless current_user&.sales?
  end

  def authorize_logistics!
    head :forbidden unless current_user&.logistics?
  end

	def set_timeline
    @project = Project.includes(
      { pi: :customer },
      { cis: [:pi, { swift: :bank }] },
      { bookings: [:release_request, { payment_orders: [:user, :bank] }] },
      { swifts: :bank },
      { ballance_projects: { ballance: [:supplier, :spi, :scis] } },
      { payment_orders: [:user, :bank, :ballance, :booking, :sci, :spi] }
    ).find(params[:id])

    @pi       = @project.pi
    @cis      = @project.cis.to_a
    @bookings = @project.bookings.to_a
    @allocates = @project.ballance_projects.to_a

    # --------------------------------------------------
    # SWIFTS
    # --------------------------------------------------

    direct_swifts = @project.swifts.to_a
    ci_swifts = @cis.filter_map(&:swift)

    @project_swifts = (direct_swifts + ci_swifts)
      .uniq(&:id)
      .sort_by { |swift| swift.confirm_at || swift.created_at || Time.at(0) }

    @advance_swifts = direct_swifts.select { |swift| swift.advance == true }

    @balance_swifts = (
      direct_swifts.reject { |swift| swift.advance == true } + ci_swifts
    ).uniq(&:id)

    @confirmed_swifts = @project_swifts.select do |swift|
      swift.confirmed == true && swift.rejected != true
    end

    @pending_swifts = @project_swifts.select do |swift|
      swift.confirmed != true && swift.rejected != true
    end

    @rejected_swifts = @project_swifts.select do |swift|
      swift.rejected == true && swift.confirmed != true
    end

    @conflicting_swifts = @project_swifts.select do |swift|
      swift.confirmed == true && swift.rejected == true
    end

    @confirmed_receipts_by_currency = @confirmed_swifts
      .group_by { |swift| swift.currency.to_s.downcase }
      .transform_values { |records| records.sum { |swift| swift.amount.to_f } }

    @bank_credits_by_currency = @confirmed_swifts
      .group_by { |swift| swift.bank&.currency.to_s.downcase }
      .reject { |currency, _| currency.blank? }
      .transform_values { |records| records.sum { |swift| swift.deposited_amount.to_f } }

    @invoice_amounts_by_currency = @cis
      .group_by { |ci| ci.pi&.currency.to_s.downcase }
      .reject { |currency, _| currency.blank? }
      .transform_values { |records| records.sum { |ci| ci.balance_payment.to_f } }

    # --------------------------------------------------
    # BOOKINGS AND PROJECT TOTALS
    # --------------------------------------------------

    @latest_booking = @bookings.max_by(&:updated_at)

    @all_bookings_done = @bookings.present? &&
                         @bookings.all?(&:payment_done)

    @any_bl_draft_attached = @bookings.any? do |booking|
      booking.bl_draft.attached?
    end

    @project_total_containers = @bookings.sum { |booking| booking.quantity.to_i }
    @project_total_picked_up  = @bookings.sum { |booking| booking.picked_up.to_i }
    @project_total_filled     = @bookings.sum { |booking| booking.filled.to_i }

    @project_total_net_weight   = @cis.sum { |ci| ci.net_weight.to_f }
    @project_total_gross_weight = @cis.sum { |ci| ci.gross_weight.to_f }

    # --------------------------------------------------
    # PAYMENT ORDERS
    #
    # 1. Directly linked to this project
    # 2. Linked to one of this project's bookings
    # 3. Shared supplier/inventory orders linked to an
    #    allocated Ballance, SCI, or SPI
    #
    # Indirect supplier orders are included only when
    # they have no project or booking assigned. This
    # avoids pulling in an order explicitly assigned
    # to a different project.
    # --------------------------------------------------

    booking_ids = @bookings.map(&:id)

    balances = @allocates.filter_map(&:ballance)

    balance_ids = balances.map(&:id).uniq
    sci_ids = balances.flat_map { |balance| balance.scis.map(&:id) }.uniq
    spi_ids = balances.filter_map { |balance| balance.spi&.id }.uniq

    payment_orders_scope = PaymentOrder.where(project_id: @project.id)

    if booking_ids.any?
      payment_orders_scope = payment_orders_scope.or(
        PaymentOrder.where(booking_id: booking_ids)
      )
    end

    if balance_ids.any?
      payment_orders_scope = payment_orders_scope.or(
        PaymentOrder.where(
          project_id: nil,
          booking_id: nil,
          ballance_id: balance_ids
        )
      )
    end

    if sci_ids.any?
      payment_orders_scope = payment_orders_scope.or(
        PaymentOrder.where(
          project_id: nil,
          booking_id: nil,
          sci_id: sci_ids
        )
      )
    end

    if spi_ids.any?
      payment_orders_scope = payment_orders_scope.or(
        PaymentOrder.where(
          project_id: nil,
          booking_id: nil,
          spi_id: spi_ids
        )
      )
    end

    @project_payment_orders = payment_orders_scope
      .distinct
      .includes(:user, :bank, :booking, :ballance, :sci, :spi)
      .order(created_at: :desc)
      .to_a

    # Identify supplier/inventory orders that are shared
    # rather than directly assigned to this project.
    @shared_supplier_payment_order_ids = @project_payment_orders.select do |order|
      order.project_id.nil? &&
        order.booking_id.nil? &&
        (
          balance_ids.include?(order.ballance_id) ||
          sci_ids.include?(order.sci_id) ||
          spi_ids.include?(order.spi_id)
        )
    end.map(&:id)

    # Human-readable explanation of why each order appears.
    @payment_order_relation_labels = {}

    @project_payment_orders.each do |order|
      label =
        if booking_ids.include?(order.booking_id)
          "Booking #{order.booking&.number || order.booking_id}"
        elsif order.project_id == @project.id
          "Project"
        elsif sci_ids.include?(order.sci_id)
          "Supplier CI #{order.sci&.number || order.sci_id}"
        elsif spi_ids.include?(order.spi_id)
          "Supplier PI #{order.spi&.number || order.spi_id}"
        elsif balance_ids.include?(order.ballance_id)
          "Shared inventory #{order.ballance&.number || order.ballance_id}"
        else
          "Related"
        end

      @payment_order_relation_labels[order.id] = label
    end

    # --------------------------------------------------
    # PAYMENT ORDER REPORTS
    #
    # Currency totals remain separate. Shared supplier
    # orders are shown separately from project/booking
    # orders; they are not treated as project-only costs.
    # --------------------------------------------------

    shared_ids = @shared_supplier_payment_order_ids

    amount_for = lambda do |records|
      records.sum do |order|
        order.amount.present? ? order.amount.to_d : 0.to_d
      end
    end

    status_definitions = {
      "wait for confirm" => {
        label: "Awaiting approval",
        color: "warning"
      },
      "wait for payment" => {
        label: "Awaiting payment",
        color: "info"
      },
      "wait for delivery" => {
        label: "Paid · awaiting delivery",
        color: "primary"
      },
      "delivered" => {
        label: "Delivered",
        color: "success"
      },
      "rejected" => {
        label: "Rejected",
        color: "danger"
      }
    }

    @payment_order_currency_reports = @project_payment_orders
      .group_by { |order| order.currency.to_s.downcase.presence || "unknown" }
      .sort_by { |currency, _| currency }
      .map do |currency, records|

        total = amount_for.call(records)

        shared_records = records.select { |order| shared_ids.include?(order.id) }
        shared_total = amount_for.call(shared_records)

        status_rows = status_definitions.map do |status, definition|
          status_records = records.select do |order|
            order.status.to_s.downcase == status
          end

          status_amount = amount_for.call(status_records)

          {
            key: status,
            label: definition[:label],
            color: definition[:color],
            count: status_records.size,
            amount: status_amount,
            percentage: total.positive? ? (status_amount / total * 100).to_f : 0
          }
        end

        other_records = records.reject do |order|
          status_definitions.key?(order.status.to_s.downcase)
        end

        if other_records.any?
          other_amount = amount_for.call(other_records)

          status_rows << {
            key: "other",
            label: "Other",
            color: "secondary",
            count: other_records.size,
            amount: other_amount,
            percentage: total.positive? ? (other_amount / total * 100).to_f : 0
          }
        end

        paid_records = records.select do |order|
          ["wait for delivery", "delivered"].include?(order.status.to_s.downcase)
        end

        {
          currency: currency,
          count: records.size,
          total: total,
          shared_total: shared_total,
          project_linked_total: total - shared_total,
          paid_total: amount_for.call(paid_records),
          statuses: status_rows
        }
      end

    # --------------------------------------------------
    # EXISTING PAYMENT ORDER STATUS GROUPS
    # --------------------------------------------------

    paid_statuses = ["wait for delivery", "delivered"]

    @paid_project_payment_orders = @project_payment_orders.select do |order|
      paid_statuses.include?(order.status.to_s.downcase)
    end

    @pending_project_payment_orders = @project_payment_orders.reject do |order|
      paid_statuses.include?(order.status.to_s.downcase)
    end

    @paid_orders_by_currency = @paid_project_payment_orders
      .group_by { |order| order.currency.to_s.downcase }
      .transform_values { |records| records.sum { |order| order.amount.to_f } }

    @pending_orders_by_currency = @pending_project_payment_orders
      .group_by { |order| order.currency.to_s.downcase }
      .transform_values { |records| records.sum { |order| order.amount.to_f } }

    # --------------------------------------------------
    # OTHER EXISTING SHOW VARIABLES
    # --------------------------------------------------

    @remains = @pi.present? ? @project.remaining_quantity : nil

    @total_balance_swift_amount =
      if @balance_swifts.map(&:currency).uniq.one?
        @balance_swifts.sum { |swift| swift.amount.to_f }
      end

    @show_turnover_report =
      (@bookings.present? && @all_bookings_done) ||
      @pi&.packing_type == "bulk"
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
