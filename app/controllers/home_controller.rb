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
    # payment order end

    #accounting tables start
    @latest_payment_orders = PaymentOrder
    .order(created_at: :desc)
    .limit(14)
    @transactions = Transaction.all.includes(:transactionable).order(created_at: :desc).limit(14)
    @banks = Bank.all
    # accounting tables end

    # sales started
    @total_pi_by_month = (0..5).map do |n|
      # Move `n` months back from the current date
      month_start = Date.current.advance(months: -n).beginning_of_month
      month_end = Date.current.advance(months: -n).end_of_month

      total = Pi.where(created_at: month_start..month_end).reduce(0) do |sum, pi|
        if pi.currency == "dirham"
          sum += pi.total_price.to_i
        elsif pi.currency == "dollar"
          sum += pi.total_price.to_i * 3.67
        else
          sum
        end
      end

      { month: month_start.strftime("%B"), total: total }
    end

    # Extract the data for the chart
    @months = @total_pi_by_month.map { |data| data[:month] }
    @totals = @total_pi_by_month.map { |data| data[:total] }


    # sales end



  end
end
