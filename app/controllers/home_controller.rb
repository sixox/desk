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
                    .limit(6)



    @total_ci_by_month = (0..5).map do |n|
      month_date = Date.current.advance(months: -n)
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      # Preload associated Pi objects to avoid N+1 queries
      total = Ci.includes(:pi).where(created_at: month_start..month_end).reduce(0) do |sum, ci|
        case ci.pi.currency.downcase
        when "dirham"
          sum += ci.total_price.to_i
        when "dollar"
          sum += ci.total_price.to_i * 3.67
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



    # sales end



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

end
