class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @q = User.ransack(params[:q])
    @users = @q.result.order(:created_at).page(params[:page]).per(10)
    if current_user.id == 31 || current_user.admin?
      @allocations = BallanceProject.all
    end
  end

  def dashboard

    if current_user.is_manager || current_user.id == 5
      
    my_open_lead_tasks = LeadTask.where(
      assigned_to_id: current_user.id,
      status: :open
    )

    @crm_dashboard = {
      active_leads: Lead.where.not(
        status: [
          Lead.statuses[:won],
          Lead.statuses[:lost]
        ]
      ).count,

      offers_in_progress: Lead.where(
        status: [
          Lead.statuses[:offer_sent],
          Lead.statuses[:negotiation]
        ]
      ).count,

      my_overdue_tasks: my_open_lead_tasks
        .where("due_on IS NOT NULL AND due_on < ?", Date.current)
        .count,

      my_tasks_today: my_open_lead_tasks
        .where(due_on: Date.current)
        .count
    }



    # vacation section start
    @vacations = Vacation.where("(DATE(start_at) <= ? AND DATE(end_at) >= ?) OR (DATE(start_at) <= ? AND DATE(end_at) >= ?)", Date.current, Date.current, Date.tomorrow, Date.tomorrow)
    @current_vacations = @vacations.select { |vacation| vacation.start_at.to_date <= Date.current && vacation.end_at.to_date >= Date.current }
    @vacations_for_tomorrow = @vacations.select { |vacation| vacation.start_at.to_date <= Date.tomorrow && vacation.end_at.to_date >= Date.tomorrow }
    # vacation end

    # payment order start
    @current_paid_rial = PaymentOrder.paid_by_currency(Date.current, 'Rial').sum(:amount)
    @current_paid_dollar = PaymentOrder.paid_by_currency(Date.current, 'Dollar').sum(:amount)
    @current_paid_dirham = PaymentOrder.paid_by_currency(Date.current, 'Dirham').sum(:amount)

    @last_month = Date.current.last_month
    @last_month_paid_rial = PaymentOrder.paid_by_currency(@last_month, 'Rial').sum(:amount)
    @last_month_paid_dollar = PaymentOrder.paid_by_currency(@last_month, 'Dollar').sum(:amount)
    @last_month_paid_dirham = PaymentOrder.paid_by_currency(@last_month, 'Dirham').sum(:amount)

    @total_payments_by_rial = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      total = BigDecimal(PaymentOrder.paid_by_currency(month_date, 'rial').sum(:amount))
      
      { month: month_date.strftime("%B"), total: total }
    end

    @total_payments_by_rial.reverse!
    @total_payments_var_rial = @total_payments_by_rial.map { |data| data[:total] }

    @total_payments_by_dirham = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      total = BigDecimal(PaymentOrder.paid_by_currency(month_date, 'dirham').sum(:amount))
      
      { month: month_date.strftime("%B"), total: total }
    end

    @total_payments_by_dirham.reverse!
    @total_payments_var_dirham = @total_payments_by_dirham.map { |data| data[:total] }

    @total_payments_by_dollar = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      total = BigDecimal(PaymentOrder.paid_by_currency(month_date, 'dollar').sum(:amount))
      
      { month: month_date.strftime("%B"), total: total }
    end

    @total_payments_by_dollar.reverse!
    @total_payments_var_dollar = @total_payments_by_dollar.map { |data| data[:total] }



    # payment order end

    #accounting tables start
    @latest_payment_orders = PaymentOrder
    .where.not(mahramane: true)
    .order(created_at: :desc)
    .limit(14)
    @transactions = Transaction.all.includes(:transactionable).order(created_at: :desc).limit(14)
    @banks = Bank.all
    # accounting tables end

    # sales started
    @total_pi_by_month = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month
      total = Pi.where(created_at: month_start..month_end).reduce(0) do |sum, pi|
        case pi.currency.downcase
        when "dirham"
          sum += pi.total_price.to_i
        when "dollar"
          sum += pi.total_price.to_i * 3.67
        else
          sum
        end
      end

      { month: month_date.strftime("%B"), total: total }
    end
    @total_pi_by_month.reverse!
    @months = (0..5).map { |n| (Date.current.advance(months: -n).strftime("%B")) }.reverse
    @totals = @total_pi_by_month.map { |data| data[:total] }
    @colors = generate_colors(@total_pi_by_month.size)
    @latest_pis = Pi.joins(:project, :customer)
                    .select('pis.*, projects.name AS project_name, projects.number As project_number, customers.nickname AS customer_nickname')
                    .order(created_at: :desc)
                    .limit(5)



    @total_ci_by_month = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      # Preload associated Pi objects to avoid N+1 queries
      total = Ci.includes(:pi).where(created_at: month_start..month_end).reduce(0) do |sum, ci|
        case ci.pi.currency.downcase
        when "dirham"
          sum += ci.balance_payment.to_i
        when "dollar"
          sum += ci.balance_payment.to_i * 3.67
        else
          sum
        end
      end

      { month: month_date.strftime("%B"), total: total }
    end

    @total_ci_by_month.reverse!
    @totals_ci = @total_ci_by_month.map { |data| data[:total] }
    @latest_cis = Ci.joins(project: :pi)  # Assuming the `Project` model has a `pi` association
                .select('cis.*, projects.number AS project_number, pis.currency AS ci_currency')
                .order(created_at: :desc)
                .limit(6)

    @total_swift_by_month = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      # Preload associated Pi objects to avoid N+1 queries
      total = Swift.where(created_at: month_start..month_end, rejected: [false, nil]).reduce(0) do |sum, swift|
        case swift.currency.downcase
        when "dirham"
          sum += swift.amount.to_i
        when "dollar"
          sum += swift.amount.to_i * 3.67
        else
          sum
        end
      end

      { month: month_date.strftime("%B"), total: total }
    end

    @total_swift_by_month.reverse!
    @totals_swifts = @total_swift_by_month.map { |data| data[:total] }

    @latest_swifts = Swift.order(created_at: :desc).limit(6)

    # sales end



    # PI and CI start
    @total_pi_quantity_by_month = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      pi_data = Pi.where(issue_date: month_start..month_end)
                  .group(:product)  # Assuming "product_name" exists in Pi table
                  .sum(:quantity)

      {
        month: month_date.strftime("%B"),
        total: pi_data.values.sum,  # Total sum of all products
        breakdown: pi_data # Hash of { "Product Name" => quantity }
      }
    end

    @total_pi_quantity_by_month.reverse!
    @totals_pi_quantity = @total_pi_quantity_by_month.map { |data| data[:total] }
    @pi_quantity_breakdown = @total_pi_quantity_by_month.map { |data| data[:breakdown] }

    @total_ci_net_weight_by_month = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      ci_data = Ci.includes(:pi)  # Avoids N+1 query issue
                 .where(issue_date: month_start..month_end)
                 .group_by { |ci| ci.pi.product }  # Group by product from associated PI
                 .transform_values { |cis| cis.sum(&:net_weight) } # Sum net_weight for each product

      {
        month: month_date.strftime("%B"),
        total: ci_data.values.sum,  # Total sum of all products' net_weight
        breakdown: ci_data # Hash of { "Product Name" => total_net_weight }
      }
    end

    @total_ci_net_weight_by_month.reverse!
    @totals_ci_net_weight = @total_ci_net_weight_by_month.map { |data| data[:total] }
    @ci_net_weight_breakdown = @total_ci_net_weight_by_month.map { |data| data[:breakdown] }



    # PI and ci end


    # Customers
@customer_portfolio = Customer360::Portfolio.new

load_project_dashboard
# Force calculations








  else
    redirect_to action: :index
  end


  end

  private

  def generate_colors(count)
    # Generate a list of distinct colors
    colors = []
    count.times do
      r = rand(0..255)
      g = rand(0..255)
      b = rand(0..255)
      colors << "rgba(#{r}, #{g}, #{b}, 0.6)"
    end
    colors
  end

  def load_project_dashboard
    project_ids = Project.select(:id)

    pending_statuses = [
      "wait for confirm",
      "wait for payment"
    ]

    pending_orders = PaymentOrder.where(status: pending_statuses)

    # ------------------------------------------
    # PROJECT-RELATED PAYMENT ORDERS
    # Direct project + booking + shared inventory
    # Count each Payment Order only once.
    # ------------------------------------------

    direct_order_ids = pending_orders
      .where(project_id: project_ids)
      .pluck(:id)

    project_booking_ids = Booking
      .where(project_id: project_ids)
      .select(:id)

    booking_order_ids = pending_orders
      .where(booking_id: project_booking_ids)
      .pluck(:id)

    allocated_balance_ids = BallanceProject.select(:ballance_id)

    allocated_sci_ids = Sci
      .where(ballance_id: allocated_balance_ids)
      .select(:id)

    allocated_spi_ids = Spi
      .where(ballance_id: allocated_balance_ids)
      .select(:id)

    shared_order_scope = pending_orders.where(
      project_id: nil,
      booking_id: nil
    )

    shared_order_ids = shared_order_scope
      .where(ballance_id: allocated_balance_ids)
      .pluck(:id)

    shared_order_ids += shared_order_scope
      .where(sci_id: allocated_sci_ids)
      .pluck(:id)

    shared_order_ids += shared_order_scope
      .where(spi_id: allocated_spi_ids)
      .pluck(:id)

    # ------------------------------------------
    # LOGISTICS OPEN
    # Include unfinished project logistics and
    # bookings not marked as complete.
    # ------------------------------------------

    logistics_open_ids = Project
      .where(logistics_done: [nil, false])
      .pluck(:id)

    logistics_open_ids += Booking
      .where(payment_done: [nil, false])
      .distinct
      .pluck(:project_id)

    # ------------------------------------------
    # UNPAID CUSTOMER INVOICES
    # CI without an associated Swift.
    # ------------------------------------------

    unpaid_ci_scope = Ci
      .left_outer_joins(:swift)
      .where(swifts: { id: nil })

    # ------------------------------------------
    # DASHBOARD SUMMARY
    # ------------------------------------------

    @project_dashboard = {
      total_projects: Project.count,

      projects_without_pi: Project
        .left_outer_joins(:pi)
        .where(pis: { id: nil })
        .distinct
        .count(:id),

      sales_open: Project
        .where(sales_done: [nil, false])
        .count,

      logistics_open: logistics_open_ids.uniq.size,

      unpaid_cis: unpaid_ci_scope
        .distinct
        .count(:id),

      pending_payment_orders: (
        direct_order_ids +
        booking_order_ids +
        shared_order_ids
      ).uniq.size
    }

    # ------------------------------------------
    # RECENT PROJECT ACTIVITY
    # ------------------------------------------

    @dashboard_recent_projects = Project
      .includes(
        { pi: :customer },
        :bookings,
        { cis: :swift }
      )
      .order(updated_at: :desc)
      .limit(8)
      .to_a

    recent_project_ids = @dashboard_recent_projects.map(&:id)

    if recent_project_ids.any?

      @dashboard_recent_unpaid_ci_counts = unpaid_ci_scope
        .where(project_id: recent_project_ids)
        .group(:project_id)
        .count

      @dashboard_recent_pending_booking_counts = Booking
        .where(
          project_id: recent_project_ids,
          payment_done: [nil, false]
        )
        .group(:project_id)
        .count

    else

      @dashboard_recent_unpaid_ci_counts = {}
      @dashboard_recent_pending_booking_counts = {}

    end
  end

end
