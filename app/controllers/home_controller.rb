class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @q = User.ransack(params[:q])
    @users = @q.result.order(:created_at).page(params[:page]).per(10)
  end

  def dashboard

    # vacation section start
    @vacations = Vacation.where("(DATE(start_at) <= ? AND DATE(end_at) >= ?) OR (DATE(start_at) <= ? AND DATE(end_at) >= ?)", Date.current, Date.current, Date.tomorrow, Date.tomorrow)
    @current_vacations = @vacations.select { |vacation| vacation.start_at.to_date <= Date.current && vacation.end_at.to_date >= Date.current }
    @vacations_for_tomorrow = @vacations.select { |vacation| vacation.start_at.to_date <= Date.tomorrow && vacation.end_at.to_date >= Date.tomorrow }
    # vacation end

    # payment order start
    current_date = Date.current
    last_month = current_date.last_month

    @paid_orders = PaymentOrder.paid_by_currency(current_date, nil)
    .or(PaymentOrder.paid_by_currency(last_month, nil))
    @current_paid_orders = @paid_orders.select { |order| order.created_at >= current_date.beginning_of_month }
    .group_by(&:currency)

    @last_month_paid_orders = @paid_orders.select { |order| order.created_at >= last_month.beginning_of_month }
    .group_by(&:currency)

    @current_paid_rial = @current_paid_orders['Rial'] || []
    @current_paid_dollar = @current_paid_orders['Dollar'] || []
    @current_paid_dirham = @current_paid_orders['Dirham'] || []

    @last_month_paid_rial = @last_month_paid_orders['Rial'] || []
    @last_month_paid_dollar = @last_month_paid_orders['Dollar'] || []
    @last_month_paid_dirham = @last_month_paid_orders['Dirham'] || []


  end
end
