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
    @current_paid_rial = PaymentOrder.paid_by_currency(Date.current, 'Rial').sum(:amount)
    @current_paid_dollar = PaymentOrder.paid_by_currency(Date.current, 'Dollar').sum(:amount)
    @current_paid_dirham = PaymentOrder.paid_by_currency(Date.current, 'Dirham').sum(:amount)

    @last_month = Date.current.last_month
    @last_month_paid_rial = PaymentOrder.paid_by_currency(@last_month, 'Rial').sum(:amount)
    @last_month_paid_dollar = PaymentOrder.paid_by_currency(@last_month, 'Dollar').sum(:amount)
    @last_month_paid_dirham = PaymentOrder.paid_by_currency(@last_month, 'Dirham').sum(:amount)




  end
end
