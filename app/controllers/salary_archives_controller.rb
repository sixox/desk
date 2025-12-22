# frozen_string_literal: true

class SalaryArchivesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_month

  def manager_review
    user_ids = current_user.direct_reports.pluck(:id) | [current_user.id]
    @users = User.where(id: user_ids).by_name

    @archives = SalaryArchive
      .includes(:days)
      .where(shamsi_month_id: @shamsi_month.id, user_id: user_ids)
      .index_by(&:user_id)

    remote_days = RemoteDay.where(
      user_id: user_ids,
      date: @shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date
    )
    @remote_days_by_user_date =
      remote_days.group_by(&:user_id).transform_values { |rows| rows.index_by(&:date) }

    overtime_entries = OvertimeEntry.where(
      user_id: user_ids,
      date: @shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date
    )
    @overtime_by_user_date =
      overtime_entries.group_by(&:user_id).transform_values { |rows| rows.group_by(&:date) }

    manual_entries = ManualEntry.where(
      user_id: user_ids,
      occurred_at: @shamsi_month.start_at.beginning_of_day..@shamsi_month.end_at.end_of_day
    )
    @manual_by_user_date = build_manual_map(manual_entries)

    @off_dates = @shamsi_month.off_dates.to_set
    @weekday_fa = %w[یکشنبه دوشنبه سه‌شنبه چهارشنبه پنجشنبه جمعه شنبه]

    @pay_type_by_user_id =
      SalaryProfile.where(user_id: user_ids)
                   .pluck(:user_id, :pay_type)
                   .to_h
                   .transform_values do |v|
        {
          "fixed" => "پرداخت ثابت",
          "hourly" => "محاسبه کامل",
          "fixed_with_overtime" => "ثابت + اضافه/کسری"
        }[v.to_s] || "نامشخص"
      end

    @vacation_info_by_user_date = build_vacation_info_map(user_ids)

    @fmt_hours = lambda do |minutes|
      m = minutes.to_i
      return 0 if m <= 0
      q = (m / 15.0).round
      (q * 0.25)
    end
  end

  def bulk_update_days
    allowed_user_ids = current_user.direct_reports.pluck(:id) | [current_user.id]
    allowed_archives = SalaryArchive.where(shamsi_month_id: @shamsi_month.id, user_id: allowed_user_ids)

    days_params      = params[:days] || {}
    remote_updates   = params[:remote_updates] || {}
    vacation_updates = params[:vacation_updates] || {}
    overtime_updates = params[:overtime_updates] || {}

    # manual totals on archives
    archives_params  = params[:archives] || {}

    touched_archive_ids = Set.new
    touched_day_ids = Set.new
    touched_user_dates = Set.new

    SalaryArchiveDay.transaction do
      vac_map_before = build_vacation_info_map(allowed_user_ids)
      ot_map_before  = build_overtime_map(allowed_user_ids)

      month_start = @shamsi_month.start_at.to_date
      month_end   = @shamsi_month.end_at.to_date

      # 0) Update manual totals on archives (minutes) — independent from days
      archives_params.each do |archive_id, attrs|
        a = allowed_archives.find_by(id: archive_id)
        next unless a

        manual_ot_min  = hours_to_minutes(attrs[:manual_overtime_hours])
        manual_def_min = hours_to_minutes(attrs[:manual_deficit_hours])

        a.update!(
          manual_overtime_minutes: manual_ot_min,
          manual_deficit_minutes: manual_def_min
        )

        touched_archive_ids << a.id
      end

      # 1) Vacation confirm toggle (touch related days)
      vacation_updates.each do |vac_id, checked|
        v = Vacation.find_by(id: vac_id)
        next unless v && allowed_user_ids.include?(v.user_id)

        v.update!(confirm: (checked.to_s == "1"))

        from = [v.start_at.to_date, month_start].max
        to   = [v.end_at.to_date,   month_end].min
        next if from > to

        archive = allowed_archives.find_by(user_id: v.user_id)
        (from..to).each do |d|
          touched_user_dates << "#{v.user_id}|#{d}"
          next unless archive
          day = archive.days.find_by(work_date: d)
          next unless day
          touched_archive_ids << archive.id
          touched_day_ids << day.id
        end
      end

      # 2) Overtime confirm toggle (ONLY outside_system)
      overtime_updates.each do |ot_id, checked|
        ot = OvertimeEntry.find_by(id: ot_id)
        next unless ot && allowed_user_ids.include?(ot.user_id)
        next unless ot.outside_system == true

        ot.update!(confirmed: (checked.to_s == "1"))
        touched_user_dates << "#{ot.user_id}|#{ot.date}"

        archive = allowed_archives.find_by(user_id: ot.user_id)
        if archive
          day = archive.days.find_by(work_date: ot.date)
          if day
            touched_archive_ids << archive.id
            touched_day_ids << day.id
          end
        end
      end

      vac_map = build_vacation_info_map(allowed_user_ids)
      ot_map  = build_overtime_map(allowed_user_ids)
      off_dates = @shamsi_month.off_dates.to_set

      # 3) Update day fields (IMPORTANT: overtime_hours is BASE hours now)
      days_params.each do |day_id, attrs|
        day = SalaryArchiveDay
          .joins(:salary_archive)
          .where(salary_archives: { id: allowed_archives.select(:id) })
          .find(day_id)

        touched_archive_ids << day.salary_archive_id
        touched_day_ids << day.id

        user_id = day.salary_archive.user_id
        d = day.work_date
        touched_user_dates << "#{user_id}|#{d}"

        vinfo = (vac_map[user_id] || {})[d]
        daily_confirmed = vinfo.present? && vinfo[:kind] == :daily && vinfo[:confirmed] == true
        if daily_confirmed
          day.update!(
            first_in_at: nil,
            last_out_at: nil,
            overtime_minutes: 0,
            deficit_minutes: 0
          )
          next
        end

        deficit_minutes = hours_to_minutes(attrs[:deficit_hours])

        # BASE overtime from input (does NOT include outside_system anymore)
        base_overtime_minutes = hours_to_minutes(attrs[:overtime_hours])

        # outside_system confirmed overtime (idempotent)
        outside_minutes = outside_system_overtime_minutes(ot_map, user_id, d)

        day.update!(
          deficit_minutes: deficit_minutes,
          overtime_minutes: base_overtime_minutes + outside_minutes,
          first_in_at: attrs[:first_in_at].to_s.strip.presence,
          last_out_at: attrs[:last_out_at].to_s.strip.presence
        )
      end

      # 4) Remote update + touch
      remote_updates.each do |remote_id, checked|
        rd = RemoteDay.find_by(id: remote_id)
        next unless rd && allowed_user_ids.include?(rd.user_id)

        rd.update!(confirmed: (checked.to_s == "1"))
        touched_user_dates << "#{rd.user_id}|#{rd.date}"

        archive = allowed_archives.find_by(user_id: rd.user_id)
        next unless archive
        day = archive.days.find_by(work_date: rd.date)
        next unless day

        touched_archive_ids << archive.id
        touched_day_ids << day.id
      end

      # 5) Recompute deficit rules for touched days
      if touched_day_ids.any?
        days = SalaryArchiveDay.includes(:salary_archive).where(id: touched_day_ids.to_a)

        remote_map = RemoteDay
          .where(user_id: allowed_user_ids, date: days.map(&:work_date))
          .group_by(&:user_id)
          .transform_values { |rows| rows.index_by(&:date) }

        days.each do |day|
          user_id = day.salary_archive.user_id
          d = day.work_date

          vinfo = (vac_map[user_id] || {})[d]
          daily_confirmed = vinfo.present? && vinfo[:kind] == :daily && vinfo[:confirmed] == true
          if daily_confirmed
            day.update!(
              first_in_at: nil,
              last_out_at: nil,
              overtime_minutes: 0,
              deficit_minutes: 0
            )
            next
          end

          rd = (remote_map[user_id] || {})[d]

          if rd && rd.confirmed == false
            req = required_minutes_for(d, off_dates: off_dates)
            day.update!(overtime_minutes: 0, deficit_minutes: req)
            next
          end

          if rd && (rd.confirmed == true || rd.confirmed.nil?)
            day.update!(deficit_minutes: 0)
            next
          end

          new_def = recompute_deficit_minutes(day, user_id, d, off_dates: off_dates, vac_map: vac_map)
          day.update!(deficit_minutes: new_def)
        end
      end

      # 6) If only overtime_confirm changed (without editing row): adjust overtime minutes idempotently
      if touched_user_dates.any?
        touched_user_dates.each do |key|
          user_id_s, date_s = key.split("|", 2)
          user_id = user_id_s.to_i
          d = Date.parse(date_s)

          archive = allowed_archives.find_by(user_id: user_id)
          next unless archive
          day = archive.days.find_by(work_date: d)
          next unless day

          vinfo = (vac_map[user_id] || {})[d]
          daily_confirmed = vinfo.present? && vinfo[:kind] == :daily && vinfo[:confirmed] == true
          next if daily_confirmed

          old_outside = outside_system_overtime_minutes(ot_map_before, user_id, d)
          new_outside = outside_system_overtime_minutes(ot_map,        user_id, d)

          base = day.overtime_minutes.to_i - old_outside
          base = 0 if base < 0

          desired = base + new_outside
          if day.overtime_minutes.to_i != desired
            day.update!(overtime_minutes: desired)
            touched_archive_ids << archive.id
            touched_day_ids << day.id
          end
        end
      end

      # 7) recalc totals (system totals from days)
      SalaryArchive.where(id: touched_archive_ids.to_a).includes(:days).find_each(&:recalculate_totals!)

      # ✅ NEW: set manager_confirmed_at / manager_confirmed_by_id on ANY save (only touched archives)
      if touched_archive_ids.any?
        SalaryArchive.where(id: touched_archive_ids.to_a).find_each do |a|
          a.update!(
            manager_confirmed_at: Time.current,
            manager_confirmed_by_id: current_user.id
          )
        end
      end

      # 8) Final confirm? (only touched archives)
      if params[:final_confirm].to_s == "1"
        SalaryArchive.where(id: touched_archive_ids.to_a).find_each do |a|
          a.update!(
            status: :manager_confirmed
          )
        end
      end
    end

    redirect_to manager_review_salary_archives_path(month_id: @shamsi_month.id), notice: "ذخیره شد."
  end



  def hr_review
    authorize_hr_review!

    # همه‌ی آرشیوهای این ماه (هر کسی که salary_archive دارد)
    scope = SalaryArchive
      .includes(:days)
      .where(shamsi_month_id: @shamsi_month.id)

    user_ids = scope.pluck(:user_id).uniq
    @users = User.where(id: user_ids).by_name

    @archives = scope.index_by(&:user_id)

    remote_days = RemoteDay.where(
      user_id: user_ids,
      date: @shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date
    )
    @remote_days_by_user_date =
      remote_days.group_by(&:user_id).transform_values { |rows| rows.index_by(&:date) }

    overtime_entries = OvertimeEntry.where(
      user_id: user_ids,
      date: @shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date
    )
    @overtime_by_user_date =
      overtime_entries.group_by(&:user_id).transform_values { |rows| rows.group_by(&:date) }

    manual_entries = ManualEntry.where(
      user_id: user_ids,
      occurred_at: @shamsi_month.start_at.beginning_of_day..@shamsi_month.end_at.end_of_day
    )
    @manual_by_user_date = build_manual_map(manual_entries)

    @off_dates = @shamsi_month.off_dates.to_set
    @weekday_fa = %w[یکشنبه دوشنبه سه‌شنبه چهارشنبه پنجشنبه جمعه شنبه]

    @pay_type_by_user_id =
      SalaryProfile.where(user_id: user_ids)
                   .pluck(:user_id, :pay_type)
                   .to_h
                   .transform_values do |v|
        {
          "fixed" => "پرداخت ثابت",
          "hourly" => "محاسبه کامل",
          "fixed_with_overtime" => "ثابت + اضافه/کسری"
        }[v.to_s] || "نامشخص"
      end

    @vacation_info_by_user_date = build_vacation_info_map(user_ids)

    @fmt_hours = lambda do |minutes|
      m = minutes.to_i
      return 0 if m <= 0
      q = (m / 15.0).round
      (q * 0.25)
    end
  end

  # ✅ NEW (Confirm برای کل این ماه) — فقط user_id==1
  def hr_confirm_all
    authorize_hr_confirm!

    SalaryArchive
      .where(shamsi_month_id: @shamsi_month.id)
      .update_all(hr_confirmed: true, hr_confirmed_at: Time.current)

    redirect_to hr_review_salary_archives_path(month_id: @shamsi_month.id),
                notice: "تأیید HR ثبت شد."
  end



  def accounting_review
    authorize_accounting_review!

    scope = SalaryArchive
      .includes(:days)
      .where(shamsi_month_id: @shamsi_month.id)

    user_ids = scope.pluck(:user_id).uniq
    @users = User.where(id: user_ids).by_name
    @archives = scope.index_by(&:user_id)

    remote_days = RemoteDay.where(
      user_id: user_ids,
      date: @shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date
    )
    @remote_days_by_user_date =
      remote_days.group_by(&:user_id).transform_values { |rows| rows.index_by(&:date) }

    overtime_entries = OvertimeEntry.where(
      user_id: user_ids,
      date: @shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date
    )
    @overtime_by_user_date =
      overtime_entries.group_by(&:user_id).transform_values { |rows| rows.group_by(&:date) }

    manual_entries = ManualEntry.where(
      user_id: user_ids,
      occurred_at: @shamsi_month.start_at.beginning_of_day..@shamsi_month.end_at.end_of_day
    )
    @manual_by_user_date = build_manual_map(manual_entries)

    @off_dates = @shamsi_month.off_dates.to_set
    @weekday_fa = %w[یکشنبه دوشنبه سه‌شنبه چهارشنبه پنجشنبه جمعه شنبه]

    @pay_type_by_user_id =
      SalaryProfile.where(user_id: user_ids)
                   .pluck(:user_id, :pay_type)
                   .to_h
                   .transform_values do |v|
        {
          "fixed" => "پرداخت ثابت",
          "hourly" => "محاسبه کامل",
          "fixed_with_overtime" => "ثابت + اضافه/کسری"
        }[v.to_s] || "نامشخص"
      end

    @vacation_info_by_user_date = build_vacation_info_map(user_ids)

    @fmt_hours = lambda do |minutes|
      m = minutes.to_i
      return 0 if m <= 0
      q = (m / 15.0).round
      (q * 0.25)
    end
  end

  # ✅ NEW (bulk confirm برای کل ماه) — فقط Accounting manager
def accounting_confirm_all
  authorize_accounting_review!

  archives = SalaryArchive.where(shamsi_month_id: @shamsi_month.id)
  user_ids = archives.pluck(:user_id).uniq

  profiles_by_user_id =
    SalaryProfile.where(user_id: user_ids).index_by(&:user_id)

  # تعداد روزهای ماه (بر اساس start_at/end_at)
  month_days = (@shamsi_month.end_at.to_date - @shamsi_month.start_at.to_date).to_i + 1

  now = Time.current

  # تابع تعدیل: مبلغ ماه 30 روزه -> به ازای 29/31 تعدیل می‌شود
  adjust_by_month_days = lambda do |monthly_amount|
    base = monthly_amount.to_i
    return 0 if base <= 0

    # daily = base / 30 ، سپس * month_days
    ((base.to_f / 30.0) * month_days).round
  end

  SalaryArchive.transaction do
    archives.find_each do |archive|
      profile = profiles_by_user_id[archive.user_id]

      # مقادیر پروفایل (nil => 0)
      seniority_base_profile      = profile&.seniority_base.to_i
      monthly_seniority_profile   = profile&.monthly_seniority_base.to_i

      housing_allowance           = profile&.housing_allowance.to_i
      food_allowance              = profile&.food_allowance.to_i
      marriage_allowance          = profile&.marriage_allowance.to_i
      child_allowance             = profile&.child_allowance.to_i
      total_salary                = profile&.total_salary.to_i

      loan_installment            = profile&.loan_installment.to_i
      fund_three_percent          = profile&.fund_three_percent.to_i
      fund_six_percent            = profile&.fund_six_percent.to_i

      hourly_rate =
        if profile&.hourly_rate.present?
          profile.hourly_rate
        else
          BigDecimal("0")
        end

      # 1) seniority_base تعدیل شده
      seniority_base_adj = adjust_by_month_days.call(seniority_base_profile)

      # 2) پایه سنوات ماهانه تعدیل شده
      monthly_seniority_adj = adjust_by_month_days.call(monthly_seniority_profile)

      # 3) بیمه:
      # (seniority_base + marriage_allowance + housing_allowance + food_allowance + payesanavat) * 0.07
      insurance_base_sum = seniority_base_adj + marriage_allowance + housing_allowance + food_allowance + monthly_seniority_adj
      insurance_value = (insurance_base_sum.to_f * 0.07).round

      archive.assign_attributes(
        accounting_confirmed: true,
        accounting_confirmed_at: now,

        # فیلدهای قبلی که از پروفایل می‌ریختیم
        seniority_base:     seniority_base_adj,
        monthly_seniority_base: monthly_seniority_adj,

        housing_allowance:  housing_allowance,
        food_allowance:     food_allowance,
        marriage_allowance: marriage_allowance,
        child_allowance:    child_allowance,
        total_salary:       total_salary,
        hourly_rate:        hourly_rate,

        loan_installment:   loan_installment,
        fund_three_percent: fund_three_percent,
        fund_six_percent:   fund_six_percent,

        # بیمه
        insurance: insurance_value
      )

      archive.save!(validate: false)
    end
  end

  redirect_to accounting_review_salary_archives_path(month_id: @shamsi_month.id),
              notice: "تأیید حسابداری ثبت شد و محاسبات (تعدیل ۲۹/۳۰/۳۱ + بیمه) داخل آرشیو ذخیره شد."
end



def payslips
  authorize_hr_review! # اگر می‌خوای محدودتر/متفاوت باشه بگو

  scope = SalaryArchive.includes(:user).where(shamsi_month_id: @shamsi_month.id)
  @archives = scope.order("user_id ASC")
end



  private

  def set_month
    @shamsi_month = ShamsiMonth.find(params[:month_id])
  end

  def hours_to_minutes(val)
    return 0 if val.blank?
    h = val.to_f
    h = (h * 4).round / 4.0
    (h * 60).round
  end

  def required_minutes_for(date, off_dates:)
    return 0 if off_dates.include?(date)
    return 240 if date.thursday?
    480
  end

  def recompute_deficit_minutes(day, user_id, date, off_dates:, vac_map:)
    req = required_minutes_for(date, off_dates: off_dates)

    work = day.work_minutes.to_i + day.manual_adjust_minutes.to_i
    base = [req - work, 0].max

    vinfo = (vac_map[user_id] || {})[date]
    hourly_confirmed =
      vinfo.present? && vinfo[:kind] == :hourly && vinfo[:confirmed] == true
    hourly_minutes = hourly_confirmed ? vinfo[:minutes].to_i : 0

    [base - hourly_minutes, 0].max
  end

  def build_vacation_info_map(user_ids)
    start_t = @shamsi_month.start_at.beginning_of_day
    end_t   = @shamsi_month.end_at.end_of_day

    vacations = Vacation
      .where(user_id: user_ids)
      .where("start_at <= ? AND end_at >= ?", end_t, start_t)
      .select(:id, :user_id, :hourly, :start_at, :end_at, :confirm, :details, :comment)

    map = Hash.new { |h, k| h[k] = {} }

    vacations.each do |v|
      confirmed = (v.confirm == true)

      if v.hourly
        d = v.start_at.to_date
        last = v.end_at.to_date
        while d <= last
          day_start = [v.start_at, d.beginning_of_day].max
          day_end   = [v.end_at,   d.end_of_day].min
          minutes = ((day_end - day_start) / 60).round
          if minutes > 0
            map[v.user_id][d] = {
              vacation_id: v.id,
              kind: :hourly,
              minutes: minutes,
              confirmed: confirmed,
              details: v.details.to_s,
              comment: v.comment.to_s
            }
          end
          d += 1.day
        end
      else
        (v.start_at.to_date..v.end_at.to_date).each do |d2|
          map[v.user_id][d2] = {
            vacation_id: v.id,
            kind: :daily,
            minutes: 0,
            confirmed: confirmed,
            details: v.details.to_s,
            comment: v.comment.to_s
          }
        end
      end
    end

    map
  end

  def build_overtime_map(user_ids)
    overtime_entries = OvertimeEntry.where(
      user_id: user_ids,
      date: @shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date
    )
    overtime_entries.group_by(&:user_id).transform_values { |rows| rows.group_by(&:date) }
  end

  def outside_system_overtime_minutes(ot_map, user_id, date)
    list = ((ot_map[user_id] || {})[date] || [])
    list = list.select { |ot| ot.outside_system == true && ot.confirmed == true }
    list.sum { |ot| (ot.hours.to_f * 60).round }
  end

  def build_manual_map(manual_entries)
    map = Hash.new { |h, k| h[k] = {} }

    manual_entries.each do |m|
      d = m.occurred_at.to_date
      map[m.user_id][d] ||= {}
      if m.is_entry
        map[m.user_id][d][:entry] = m
      else
        map[m.user_id][d][:exit] = m
      end
    end

    map
  end

  def authorize_hr_review!
    allowed =
      (current_user.procurement? && current_user.is_manager) ||
      (current_user.hr? && current_user.is_manager) ||
      (current_user.id == 1) ||
      current_user.ceo? ||
      current_user.cob?

    head :forbidden unless allowed
  end

  def authorize_hr_confirm!
    head :forbidden unless current_user.id == 1
  end

  def authorize_accounting_review!
    head :forbidden unless (current_user.accounting? && current_user.is_manager)
  end


end
