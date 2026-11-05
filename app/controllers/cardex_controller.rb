class CardexController < ApplicationController
  before_action :authenticate_user!

  def show
    @today = Date.current

    # ------------------------------------------
    # EMPLOYEE / MANAGER SCOPE
    # Used by CRM only
    # ------------------------------------------

    @is_manager = current_user.is_manager

    @team_users =
      if @is_manager
        current_user.direct_reports.by_name
      else
        User.none
      end

    @team_user_ids = @team_users.pluck(:id)

    @visible_owner_ids = [current_user.id] + @team_user_ids

    # ------------------------------------------
    # PERSONAL CRM FOLLOW-UPS
    # ------------------------------------------

    @my_tasks_scope = LeadTask.open.where(
      assigned_to_id: current_user.id
    )

    @my_open_tasks_count = @my_tasks_scope.count

    @my_overdue_count = @my_tasks_scope
      .where("due_on < ?", @today)
      .count

    @my_today_count = @my_tasks_scope
      .where(due_on: @today)
      .count

    @my_tasks = @my_tasks_scope
      .includes(:lead)
      .order(
        Arel.sql("CASE WHEN due_on IS NULL THEN 1 ELSE 0 END ASC"),
        due_on: :asc,
        created_at: :desc
      )
      .limit(8)

    # ------------------------------------------
    # MANAGER TEAM WORKLOAD
    # ------------------------------------------

    @team_tasks_scope = LeadTask.open.where(
      assigned_to_id: @team_user_ids
    )

    @team_open_tasks_count = @team_tasks_scope.count

    @team_overdue_count = @team_tasks_scope
      .where("due_on < ?", @today)
      .count

    @team_today_count = @team_tasks_scope
      .where(due_on: @today)
      .count

    @team_tasks = @team_tasks_scope
      .includes(:lead, :assigned_to)
      .order(
        Arel.sql("CASE WHEN due_on IS NULL THEN 1 ELSE 0 END ASC"),
        due_on: :asc,
        created_at: :desc
      )
      .limit(8)

    # ------------------------------------------
    # SALES WORKSPACE ACCESS
    # ------------------------------------------

    @sales_access =
      current_user.is_manager ||
      current_user.is_marketing ||
      current_user.sales? ||
      current_user.admin?

    if @sales_access

      @my_leads_count = Lead.where(
        owner_id: current_user.id
      ).count

      @team_leads_count = Lead.where(
        owner_id: @team_user_ids
      ).count

      sales_leads = Lead.where(
        owner_id: @visible_owner_ids
      )

      @sales_leads_count = sales_leads.count

      raw_pipeline_counts = sales_leads.group(:status).count

      @sales_status_order = Lead.statuses.keys

      @sales_pipeline_counts = @sales_status_order.index_with do |status|
        raw_pipeline_counts[status] ||
          raw_pipeline_counts[status.to_sym] ||
          0
      end

      @recent_sales_leads = sales_leads
        .includes(:owner)
        .order(updated_at: :desc)
        .limit(6)

    else

      @my_leads_count = 0
      @team_leads_count = 0
      @sales_leads_count = 0
      @sales_status_order = []
      @sales_pipeline_counts = {}
      @recent_sales_leads = Lead.none

    end

    # ------------------------------------------
    # CUSTOMER FINANCIAL ATTENTION
    # CRM ownership scope remains unchanged
    # ------------------------------------------

    if @sales_access

      customer_scope = Customer.where(
        user_id: @visible_owner_ids
      )

      customer_portfolio = Customer360::Portfolio.new(
        customers: customer_scope
      )

      @cardex_customer_rows = customer_portfolio.customer_summaries.select do |row|
        row[:outstanding_amounts].values.any?(&:positive?) ||
          row[:pending_receipt_amounts].values.any?(&:positive?)
      end

    else

      @cardex_customer_rows = []

    end

    # ------------------------------------------
    # PROJECT OPERATIONS
    # Company-wide, not scoped by CRM ownership
    # ------------------------------------------

    load_project_operations
  end

  private

  def load_project_operations
    project_ids = Project.pluck(:id)

    if project_ids.empty?
      @cardex_project_rows = []
      @cardex_project_rows_total = 0
      @cardex_pending_logistics_count = 0
      @cardex_pending_payment_count = 0
      @cardex_unpaid_ci_count = 0
      @cardex_unfinished_project_count = 0
      return
    end

    # ------------------------------------------
    # RECENT AND UNFINISHED PROJECTS
    # ------------------------------------------

    recent_project_ids = Project
      .order(updated_at: :desc)
      .limit(6)
      .pluck(:id)

    unfinished_projects = Project
      .where(sales_done: [false, nil])
      .or(Project.where(logistics_done: [false, nil]))

    unfinished_project_ids = unfinished_projects
      .order(updated_at: :desc)
      .limit(12)
      .pluck(:id)

    @cardex_unfinished_project_count = unfinished_projects.count

    # ------------------------------------------
    # PENDING LOGISTICS
    #
    # A project is included when it has bookings
    # and either the project logistics or at least
    # one booking is not marked complete.
    # ------------------------------------------

    pending_booking_project_ids = Booking
      .where(
        project_id: project_ids,
        payment_done: [false, nil]
      )
      .distinct
      .pluck(:project_id)

    unfinished_logistics_project_ids = Project
      .joins(:bookings)
      .where(
        id: project_ids,
        logistics_done: [false, nil]
      )
      .distinct
      .pluck(:id)

    logistics_project_ids = (
      pending_booking_project_ids +
      unfinished_logistics_project_ids
    ).uniq

    @cardex_pending_logistics_count = logistics_project_ids.size

    # ------------------------------------------
    # UNPAID CUSTOMER INVOICES
    #
    # A CI without an associated Swift.
    # ------------------------------------------

    unpaid_ci_project_ids = Ci
      .left_outer_joins(:swift)
      .where(
        project_id: project_ids,
        swifts: { id: nil }
      )
      .distinct
      .pluck(:project_id)

    @cardex_unpaid_ci_count = unpaid_ci_project_ids.size

    # ------------------------------------------
    # PROJECT / BOOKING / INVENTORY RELATIONSHIPS
    # ------------------------------------------

    booking_rows = Booking
      .where(project_id: project_ids)
      .pluck(:id, :project_id)

    booking_project_map = booking_rows.to_h

    allocation_rows = BallanceProject
      .where(project_id: project_ids)
      .pluck(:project_id, :ballance_id)

    projects_by_balance = Hash.new { |hash, key| hash[key] = [] }

    allocation_rows.each do |project_id, balance_id|
      projects_by_balance[balance_id] << project_id
    end

    balance_ids = allocation_rows.map(&:last).uniq

    sci_rows =
      if balance_ids.any?
        Sci.where(ballance_id: balance_ids).pluck(:id, :ballance_id)
      else
        []
      end

    spi_rows =
      if balance_ids.any?
        Spi.where(ballance_id: balance_ids).pluck(:id, :ballance_id)
      else
        []
      end

    sci_balance_map = sci_rows.to_h
    spi_balance_map = spi_rows.to_h

    sci_ids = sci_rows.map(&:first)
    spi_ids = spi_rows.map(&:first)

    # ------------------------------------------
    # PENDING PAYMENT ORDERS
    #
    # Direct project orders
    # Booking orders
    # Shared supplier/inventory orders
    #
    # Shared orders are labelled separately.
    # ------------------------------------------

    pending_statuses = [
      "wait for confirm",
      "wait for payment"
    ]

    payment_base = PaymentOrder.where(status: pending_statuses)

    payment_scopes = []

    payment_scopes << payment_base.where(
      project_id: project_ids
    )

    if booking_project_map.any?
      payment_scopes << payment_base.where(
        booking_id: booking_project_map.keys
      )
    end

    if balance_ids.any?
      payment_scopes << payment_base.where(
        project_id: nil,
        booking_id: nil,
        ballance_id: balance_ids
      )
    end

    if sci_ids.any?
      payment_scopes << payment_base.where(
        project_id: nil,
        booking_id: nil,
        sci_id: sci_ids
      )
    end

    if spi_ids.any?
      payment_scopes << payment_base.where(
        project_id: nil,
        booking_id: nil,
        spi_id: spi_ids
      )
    end

    pending_payment_scope = payment_scopes.reduce do |combined, scope|
      combined.or(scope)
    end

    pending_payment_orders =
      pending_payment_scope ? pending_payment_scope.to_a : []

    pending_orders_by_project = Hash.new { |hash, key| hash[key] = [] }

    pending_payment_orders.each do |order|

      # Direct project assignment has priority.
      if project_ids.include?(order.project_id)
        pending_orders_by_project[order.project_id] << {
          order: order,
          shared: false
        }

        next
      end

      # A booking belongs to one project.
      booking_project_id = booking_project_map[order.booking_id]

      if booking_project_id.present?
        pending_orders_by_project[booking_project_id] << {
          order: order,
          shared: false
        }

        next
      end

      # Supplier advances can be shared by several
      # projects using the same allocated inventory.
      related_balance_ids = [
        order.ballance_id,
        sci_balance_map[order.sci_id],
        spi_balance_map[order.spi_id]
      ].compact.uniq

      related_project_ids = related_balance_ids.flat_map do |balance_id|
        projects_by_balance[balance_id]
      end.uniq

      related_project_ids.each do |project_id|
        pending_orders_by_project[project_id] << {
          order: order,
          shared: true
        }
      end

    end

    @cardex_pending_payment_count = pending_orders_by_project.keys.size

    # ------------------------------------------
    # BUILD PROJECT ROWS
    # ------------------------------------------

    candidate_project_ids = (
      recent_project_ids +
      unfinished_project_ids +
      logistics_project_ids +
      unpaid_ci_project_ids +
      pending_orders_by_project.keys
    ).uniq

    projects = Project
      .where(id: candidate_project_ids)
      .includes(
        { pi: :customer },
        { cis: :swift },
        :bookings
      )
      .order(updated_at: :desc)
      .to_a

    rows = projects.map do |project|

      pending_cis = project.cis.count do |ci|
        ci.swift.nil?
      end

      pending_bookings = project.bookings.count do |booking|
        booking.payment_done != true
      end

      payment_items = pending_orders_by_project[project.id] || []

      shared_payment_count = payment_items.count do |item|
        item[:shared]
      end

      {
        project: project,
        customer: project.pi&.customer,
        pending_logistics: logistics_project_ids.include?(project.id),
        pending_booking_count: pending_bookings,
        pending_payment_count: payment_items.size,
        shared_payment_count: shared_payment_count,
        unpaid_ci_count: pending_cis,
        sales_open: project.sales_done != true,
        logistics_open: project.logistics_done != true,
        unfinished: project.sales_done != true ||
                    project.logistics_done != true,
        needs_attention:
          logistics_project_ids.include?(project.id) ||
          payment_items.any? ||
          pending_cis.positive?,
        recently_updated: recent_project_ids.include?(project.id)
      }
    end

    # Attention items first, then latest updates.
    rows.sort_by! do |row|
      [
        row[:needs_attention] ? 0 : 1,
        -(row[:project].updated_at&.to_i || 0)
      ]
    end

    @cardex_project_rows_total = rows.size
    @cardex_project_rows = rows.first(10)
  end
end