class SalaryArchiveBuilder
  FLEX_START  = "08:30"
  FLEX_END    = "09:15"
  NORMAL_MIN  = 8 * 60
  THU_MIN     = 4 * 60
  MONTHLY_DEFICIT_THRESHOLD = 60

  def initialize(user:, shamsi_month:)
    @user  = user
    @month = shamsi_month
    @off_dates = @month.off_dates
    @profile = @user.salary_profile
  end

  def build!
    archive = SalaryArchive.find_or_initialize_by(user: @user, shamsi_month: @month)
    archive.status ||= :draft
    return archive if archive.persisted? && archive.confirmed?

    archive.days.destroy_all if archive.persisted?

    rows =
      if @profile.pay_type == "fixed"
        compute_days_fixed
      else
        compute_days_with_logs
      end

    total_work = total_ot = total_def = 0

    rows.each do |row|
      archive.days.build(row)
      total_work += row[:work_minutes].to_i
      total_ot   += row[:overtime_minutes].to_i
      total_def  += row[:deficit_minutes].to_i
    end

    archive.total_work_minutes = total_work
    archive.overtime_minutes   = total_ot
    archive.deficit_minutes    = total_def

    salary_total = @profile.total_salary.to_i
    hourly_wage  = salary_total.zero? ? @profile.hourly_rate.to_f : salary_total / 192.0

    archive.bonus =
      ((archive.total_overtime_minutes_final / 60.0) * hourly_wage * 1.4).round(2)

    penalty_minutes = archive.total_deficit_minutes_final
    penalty_minutes = 0 if penalty_minutes <= MONTHLY_DEFICIT_THRESHOLD
    archive.penalty =
      ((penalty_minutes / 60.0) * hourly_wage).round(2)

    archive.save!
    archive
  end

  private

  # --- WDMS action_time (NO timezone, NO conversion) ---
  def action_time_local(tx)
    raw = tx.raw_payload.is_a?(String) ? JSON.parse(tx.raw_payload) : tx.raw_payload
    # Time.strptime(raw["action_time"], "%Y-%m-%d %H:%M:%S") ******
    Time.strptime(raw["upload_time"], "%Y-%m-%d %H:%M:%S")

  end

  def compute_days_fixed
    rows = []
    each_month_day do |date|
      next rows << base_row(date) if off_day?(date)

      remote = @user.remote_days.find_by(date: date)
      req = required_minutes_for(date)

      if remote
        if remote.confirmed == false
          rows << base_row(date).merge(deficit_minutes: req, note: "غیبت (رد Remote)")
        else
          rows << base_row(date).merge(work_minutes: req, note: "Remote")
        end
        next
      end

      rows << base_row(date).merge(work_minutes: req)
    end
    rows
  end

  def compute_days_with_logs
    rows = []

    txs = []
    if @user.wdms_employee_mapping
      emp = @user.wdms_employee_mapping.emp_code
      txs = WdmsTransaction.where(emp_code: emp)
                           .select { |t| in_month?(action_time_local(t)) }
    end

    manual = @user.manual_entries
                  .where(occurred_at: @month.start_at..@month.end_at)
                  .to_a

    by_date = (txs + manual).group_by do |r|
      r.is_a?(WdmsTransaction) ? action_time_local(r).to_date : r.occurred_at.to_date
    end

    each_month_day do |date|
      next rows << base_row(date) if off_day?(date)

      remote = @user.remote_days.find_by(date: date)
      req = required_minutes_for(date)

      if remote
        if remote.confirmed == false
          rows << base_row(date).merge(deficit_minutes: req, note: "غیبت (رد Remote)")
        else
          rows << base_row(date).merge(work_minutes: req, note: "Remote")
        end
        next
      end

      times = (by_date[date] || []).map do |r|
        r.is_a?(WdmsTransaction) ? action_time_local(r) : r.occurred_at
      end.compact.sort

      if times.size < 2
        rows << base_row(date).merge(deficit_minutes: req, note: "غیبت")
        next
      end

      first_in = times.first
      last_out = times.last
      metrics  = compute_day_metrics(date, first_in, last_out)

      rows << base_row(date).merge(
        first_in_at: first_in.strftime("%H:%M"),
        last_out_at: last_out.strftime("%H:%M"),
        work_minutes: metrics[:work],
        overtime_minutes: metrics[:overtime],
        deficit_minutes: metrics[:deficit]
      )
    end

    rows
  end

  def compute_day_metrics(date, first_in, last_out)
    return blank_metrics if last_out <= first_in

    flex_start = Time.strptime("#{date} #{FLEX_START}", "%Y-%m-%d %H:%M")
    flex_end   = Time.strptime("#{date} #{FLEX_END}", "%Y-%m-%d %H:%M")
    req        = required_minutes_for(date)

    basis_in =
      if first_in < flex_start then flex_start
      elsif first_in > flex_end then flex_end
      else first_in
      end

    expected_out =
      first_in > flex_end ? fixed_out(date) : basis_in + req.minutes

    work     = ((last_out - first_in) / 60).round
    deficit  =
      [((first_in - flex_end) / 60).round, 0].max +
      [((expected_out - last_out) / 60).round, 0].max

    overtime =
      [((flex_start - first_in) / 60).round, 0].max +
      [((last_out - expected_out) / 60).round, 0].max

    { work: work, deficit: deficit, overtime: overtime }
  end

  def fixed_out(date)
    Time.strptime("#{date} #{date.thursday? ? '13:15' : '17:15'}", "%Y-%m-%d %H:%M")
  end

  def base_row(date)
    {
      work_date: date,
      first_in_at: nil,
      last_out_at: nil,
      work_minutes: 0,
      overtime_minutes: 0,
      deficit_minutes: 0,
      manual_adjust_minutes: 0,
      note: nil
    }
  end

  def blank_metrics
    { work: 0, deficit: 0, overtime: 0 }
  end

  def required_minutes_for(date)
    date.thursday? ? THU_MIN : NORMAL_MIN
  end

  def off_day?(date)
    date.friday? || @off_dates.include?(date)
  end

  def each_month_day(&block)
    (@month.start_at.to_date..@month.end_at.to_date).each(&block)
  end

  def in_month?(time)
    d = time.to_date
    d >= @month.start_at.to_date && d <= @month.end_at.to_date
  end
end
