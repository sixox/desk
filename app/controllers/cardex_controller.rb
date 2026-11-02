
class CardexController < ApplicationController
  before_action :authenticate_user!

  def show
    @today = Date.current

    # ------------------------------------------
    # EMPLOYEE / MANAGER SCOPE
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
    # Only customers owned by the user or direct reports
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

  end
end
