class PayrollAttendancesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_month

  def index
    # فقط کارمندهایی که mapping دارند
    @users = User
               .joins(:wdms_employee_mapping)
               .includes(:wdms_employee_mapping)
               .order(:id)
  end

  def show
    @user = User.includes(:wdms_employee_mapping).find(params[:user_id])
    @mapping = @user.wdms_employee_mapping

    unless @mapping&.emp_code.present?
      return redirect_to payroll_month_payroll_attendances_path(@month),
        alert: "This user has no WDMS employee mapping."
    end

    tz = ActiveSupport::TimeZone["Asia/Tehran"] || Time.zone

    @days = @month.payroll_days.order(:day_on)

    # Pull all transactions for the whole month in one query (fast)
    start_time = tz.parse(@month.start_on.to_s).beginning_of_day
    end_time   = tz.parse(@month.end_on.to_s).end_of_day

    txs = WdmsTransaction
            .where(emp_code: @mapping.emp_code)
            .where(occurred_at: start_time..end_time)
            .order(:occurred_at)
            .to_a

    # group by day
    @by_date = txs.group_by { |t| t.occurred_at.in_time_zone(tz).to_date }

    # Build rows per day
    @rows = @days.map do |day|
      date = day.day_on
      list = (@by_date[date] || [])

      # first/last for the day
      first_in  = list.first&.occurred_at&.in_time_zone(tz)
      last_out  = list.last&.occurred_at&.in_time_zone(tz)

      worked_seconds = compute_worked_seconds(list, tz)

      status =
        if day.holiday
          :holiday
        elsif list.empty?
          :absent
        elsif list.size.odd?
          :incomplete
        else
          :present
        end

      OpenStruct.new(
        date: date,
        weekday: date.strftime("%A"),
        holiday: day.holiday,
        note: day.note,
        tx_count: list.size,
        first_in: first_in,
        last_out: last_out,
        worked_seconds: worked_seconds,
        status: status
      )
    end

    # totals
    @total_worked_seconds = @rows.sum(&:worked_seconds)
    @absent_days = @rows.count { |r| r.status == :absent }
    @incomplete_days = @rows.count { |r| r.status == :incomplete }
  end

  private

  def set_month
    @month = PayrollMonth.find(params[:payroll_month_id])
  end

  # Pair transactions: (1,2), (3,4) ... and sum durations
  # If odd count, last one is ignored (incomplete day)
  def compute_worked_seconds(list, tz)
    times = list.map { |t| t.occurred_at.in_time_zone(tz) }
    return 0 if times.size < 2

    sum = 0
    times.each_slice(2) do |a, b|
      break if b.nil?
      diff = (b - a).to_i
      sum += diff if diff.positive?
    end
    sum
  end
end
