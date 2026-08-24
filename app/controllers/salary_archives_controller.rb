# app/controllers/salary_archives_controller.rb
class SalaryArchivesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_month, except: [:rebuild_last_month]

  def manager_review
    user_ids = current_user.direct_reports.pluck(:id) | [current_user.id]

    user_ids = User
      .where(id: user_ids)
      .joins(:salary_profile)
      .pluck(:id)

    @users = User.where(id: user_ids).by_name

    @archives = SalaryArchive
      .includes(:days)
      .where(
        shamsi_month_id: @shamsi_month.id,
        user_id: user_ids
      )
      .index_by(&:user_id)

    load_review_data(user_ids)
  end

  def bulk_update_days
    allowed_user_ids =
      current_user.direct_reports.pluck(:id) | [current_user.id]

    allowed_user_ids =
      User
        .where(id: allowed_user_ids)
        .joins(:salary_profile)
        .pluck(:id)

    allowed_archives =
      SalaryArchive.where(
        shamsi_month_id: @shamsi_month.id,
        user_id: allowed_user_ids
      )

    days_params      = params[:days] || {}
    remote_updates   = params[:remote_updates] || {}
    vacation_updates = params[:vacation_updates] || {}
    overtime_updates = params[:overtime_updates] || {}
    archives_params  = params[:archives] || {}

    touched_archive_ids = Set.new
    touched_day_ids     = Set.new

    SalaryArchive.transaction do
      month_start = @shamsi_month.start_at.to_date
      month_end   = @shamsi_month.end_at.to_date

      # ------------------------------------------------------------
      # 1. Update archive-level manual values
      # ------------------------------------------------------------

      archives_params.each do |archive_id, attrs|
        archive = allowed_archives.find_by(id: archive_id)
        next unless archive

        attrs ||= {}

        archive.update!(
          manual_overtime_minutes:
            hours_to_minutes(attrs[:manual_overtime_hours]),

          manual_deficit_minutes:
            hours_to_minutes(attrs[:manual_deficit_hours])
        )

        if attrs.key?(:no_dificit)
          archive.update!(
            no_dificit: attrs[:no_dificit].to_s == "1"
          )
        elsif archive.user.salary_profile&.pay_type == "fixed_with_overtime"
          archive.update!(
            no_dificit: true
          )
        end

        touched_archive_ids << archive.id
      end

      # ------------------------------------------------------------
      # 2. Vacation confirmations
      # ------------------------------------------------------------

      vacation_updates.each do |vac_id, checked|
        vacation = Vacation.find_by(id: vac_id)
        next unless vacation
        next unless allowed_user_ids.include?(vacation.user_id)

        vacation.update!(
          confirm: checked.to_s == "1"
        )

        from = [
          vacation.start_at.to_date,
          month_start
        ].max

        to = [
          vacation.end_at.to_date,
          month_end
        ].min

        next if from > to

        archive =
          allowed_archives.find_by(
            user_id: vacation.user_id
          )

        next unless archive

        (from..to).each do |date|
          day =
            archive.days.find_by(
              work_date: date
            )

          next unless day

          touched_archive_ids << archive.id
          touched_day_ids << day.id
        end
      end

      # ------------------------------------------------------------
      # 3. External overtime confirmations
      # ------------------------------------------------------------

      overtime_updates.each do |ot_id, checked|
        overtime = OvertimeEntry.find_by(id: ot_id)
        next unless overtime
        next unless allowed_user_ids.include?(overtime.user_id)

        overtime.update!(
          confirmed: checked.to_s == "1"
        )

        archive =
          allowed_archives.find_by(
            user_id: overtime.user_id
          )

        next unless archive

        day =
          archive.days.find_by(
            work_date: overtime.date
          )

        next unless day

        touched_archive_ids << archive.id
        touched_day_ids << day.id
      end

      # ------------------------------------------------------------
      # 4. Update submitted day values
      # ------------------------------------------------------------

      days_params.each do |day_id, attrs|
        day =
          SalaryArchiveDay
            .joins(:salary_archive)
            .where(
              salary_archives: {
                id: allowed_archives.select(:id)
              }
            )
            .find(day_id)

        attrs ||= {}

        fi =
          normalize_hhmm(
            attrs[:first_in_at]
          )

        lo =
          normalize_hhmm(
            attrs[:last_out_at]
          )

        day.update!(
          first_in_at: fi,
          last_out_at: lo
        )

        touched_archive_ids << day.salary_archive_id
        touched_day_ids << day.id
      end

      # ------------------------------------------------------------
      # 5. Remote day confirmations
      # ------------------------------------------------------------

      remote_updates.each do |remote_id, checked|
        remote_day = RemoteDay.find_by(id: remote_id)
        next unless remote_day
        next unless allowed_user_ids.include?(remote_day.user_id)

        remote_day.update!(
          confirmed: checked.to_s == "1"
        )

        archive =
          allowed_archives.find_by(
            user_id: remote_day.user_id
          )

        next unless archive

        day =
          archive.days.find_by(
            work_date: remote_day.date
          )

        next unless day

        touched_archive_ids << archive.id
        touched_day_ids << day.id
      end

      # ------------------------------------------------------------
      # 6. Build current maps AFTER all updates
      # ------------------------------------------------------------

      vac_map =
        build_vacation_info_map(
          allowed_user_ids
        )

      vacation_intervals_map =
        build_vacation_intervals_map(
          allowed_user_ids
        )

      ot_map =
        build_overtime_map(
          allowed_user_ids
        )

      mission_map =
        build_mission_map(
          allowed_user_ids
        )

      off_dates =
        @shamsi_month.off_dates.to_set

      global_remote_dates =
        fetch_global_remote_dates(
          @shamsi_month
        )

      # ------------------------------------------------------------
      # 7. Recalculate ONLY touched days
      # ------------------------------------------------------------

      if touched_day_ids.any?
        days =
          SalaryArchiveDay
            .includes(:salary_archive)
            .where(id: touched_day_ids.to_a)

        days.each do |day|
          recalculate_salary_archive_day!(
            day: day,
            vac_map: vac_map,
            vacation_intervals_map:
              vacation_intervals_map,
            ot_map: ot_map,
            mission_map: mission_map,
            off_dates: off_dates,
            global_remote_dates:
              global_remote_dates
          )
        end
      end

      # ------------------------------------------------------------
      # 8. Recalculate archive totals
      # ------------------------------------------------------------

      if touched_archive_ids.any?
        SalaryArchive
          .where(id: touched_archive_ids.to_a)
          .includes(:days, :user)
          .find_each(&:recalculate_totals!)
      end

      # ------------------------------------------------------------
      # 9. Recalculate mission payroll
      # ------------------------------------------------------------

      if touched_archive_ids.any?
        recalculate_mission_payroll_for_archives(
          SalaryArchive
            .where(id: touched_archive_ids.to_a)
            .includes(:user)
        )
      end

      # ------------------------------------------------------------
      # 10. Manager confirmation
      # ------------------------------------------------------------

      if touched_archive_ids.any?
        SalaryArchive
          .where(id: touched_archive_ids.to_a)
          .find_each do |archive|

          archive.update!(
            manager_confirmed_at: Time.current,
            manager_confirmed_by_id:
              current_user.id
          )
        end
      end

      # ------------------------------------------------------------
      # 11. Final confirmation
      # ------------------------------------------------------------

      if params[:final_confirm].to_s == "1"
        SalaryArchive
          .where(id: touched_archive_ids.to_a)
          .find_each do |archive|

          archive.update!(
            status: :manager_confirmed
          )
        end
      end
    end

    redirect_to manager_review_salary_archives_path(
      month_id: @shamsi_month.id
    ),
    notice: "ذخیره شد."
  end

  def hr_review
    authorize_hr_review!

    scope =
      SalaryArchive
        .includes(:days)
        .where(
          shamsi_month_id: @shamsi_month.id
        )
        .joins(user: :salary_profile)

    user_ids =
      scope.pluck(:user_id).uniq

    @users =
      User.where(id: user_ids).by_name

    @archives =
      scope.index_by(&:user_id)

    load_review_data(user_ids)
  end

  def hr_confirm_all
    authorize_hr_confirm!

    SalaryArchive
      .joins(user: :salary_profile)
      .where(
        shamsi_month_id: @shamsi_month.id
      )
      .update_all(
        hr_confirmed: true,
        hr_confirmed_at: Time.current
      )

    redirect_to hr_review_salary_archives_path(
      month_id: @shamsi_month.id
    ),
    notice: "تأیید HR ثبت شد."
  end

  def accounting_review
    authorize_accounting_review!

    scope =
      SalaryArchive
        .includes(:days)
        .where(
          shamsi_month_id: @shamsi_month.id
        )
        .joins(user: :salary_profile)

    user_ids =
      scope.pluck(:user_id).uniq

    @users =
      User.where(id: user_ids).by_name

    @archives =
      scope.index_by(&:user_id)

    load_review_data(user_ids)
  end

  def rebuild_last_month
    authorize_accounting_review!

    last_month =
      ShamsiMonth.order(
        start_at: :asc
      ).last

    unless last_month
      redirect_back(
        fallback_location: root_path,
        alert: "هیچ ماهی پیدا نشد."
      )
      return
    end

    SalaryArchive.transaction do
      archives =
        SalaryArchive.where(
          shamsi_month_id: last_month.id
        )

      SalaryArchiveDay
        .where(
          salary_archive_id:
            archives.select(:id)
        )
        .delete_all

      archives.delete_all
    end

    GenerateArchivesJob.perform_now(
      last_month.id
    )

    redirect_to salary_admin_path,
                notice:
                  "آرشیو ماه #{last_month.name} پاک شد و دوباره ساخته شد."
  end

  def calculate_vacations
    ActiveRecord::Base.transaction do
      @shamsi_month.lock!

      if @shamsi_month.finalized?
        redirect_to accounting_review_salary_archives_path(
          month_id: @shamsi_month.id
        ),
        alert: "This month is already closed."

        return
      end

      start_date =
        @shamsi_month.start_at

      end_date =
        @shamsi_month.end_at

      vacations_by_user =
        Vacation
          .includes(:user)
          .where(
            "start_at <= ? AND end_at >= ?",
            end_date,
            start_date
          )
          .group_by(&:user)

      vacations_by_user.each do |user, vacations|
        total_days = 0
        total_hours = 0.0

        vacations.each do |vacation|
          if vacation.hourly?
            hours =
              (
                (vacation.end_at -
                 vacation.start_at) /
                1.hour
              ).round(5)

            total_hours += hours
          else
            overlap_start = [
              vacation.start_at.to_date,
              start_date.to_date
            ].max

            overlap_end = [
              vacation.end_at.to_date,
              end_date.to_date
            ].min

            days =
              (
                overlap_end -
                overlap_start
              ).to_i + 1

            total_days += days
          end
        end

        used_vacation =
          total_days +
          (total_hours / 8.0)

        if used_vacation > 0 &&
           user.salary_profile.present?

          user.salary_profile.update!(
            remain_vacation:
              user.salary_profile.remain_vacation -
              used_vacation.round(5) +
              2.5
          )

          salary_archive =
            user.salary_archives.find_by(
              shamsi_month_id:
                @shamsi_month.id
            )

          if salary_archive
            salary_archive.update!(
              remain_vacation:
                user.salary_profile.reload
                  .remain_vacation
            )
          end
        end
      end

      @shamsi_month.salary_archives
        .includes(:user)
        .each do |salary_archive|

        next if salary_archive.remain_vacation.present?

        if salary_archive.user.salary_profile
          &.remain_vacation.present?

          salary_archive.update!(
            remain_vacation:
              salary_archive.user
                .salary_profile
                .remain_vacation +
              2.5
          )
        end
      end

      recalculate_mission_payroll_for_archives(
        @shamsi_month.salary_archives
          .includes(:user)
      )

      @shamsi_month.update!(
        finalized: true
      )
    end

    redirect_to accounting_review_salary_archives_path(
      month_id: @shamsi_month.id
    ),
    notice: "This month closed."
  end

  def accounting_confirm_all
    authorize_accounting_review!

    archives =
      SalaryArchive
        .where(
          shamsi_month_id:
            @shamsi_month.id
        )
        .joins(user: :salary_profile)

    user_ids =
      archives.pluck(:user_id).uniq

    profiles_by_user_id =
      SalaryProfile
        .where(user_id: user_ids)
        .index_by(&:user_id)

    month_days =
      (
        @shamsi_month.end_at.to_date -
        @shamsi_month.start_at.to_date
      ).to_i + 1

    now = Time.current

    adjust_by_month_days =
      lambda do |monthly_amount|
        base = monthly_amount.to_i
        return 0 if base <= 0

        (
          (base.to_f / 30.0) *
          month_days
        ).round
      end

    SalaryArchive.transaction do
      archives.find_each do |archive|
        profile =
          profiles_by_user_id[
            archive.user_id
          ]

        seniority_base_profile =
          profile&.seniority_base.to_i

        monthly_seniority_profile =
          profile&.monthly_seniority_base.to_i

        housing_allowance =
          profile&.housing_allowance.to_i

        food_allowance =
          profile&.food_allowance.to_i

        marriage_allowance =
          profile&.marriage_allowance.to_i

        child_allowance =
          profile&.child_allowance.to_i

        total_salary =
          profile&.total_salary.to_i

        loan_installment =
          profile&.loan_installment.to_i

        fund_three_percent =
          profile&.fund_three_percent.to_i

        fund_six_percent =
          profile&.fund_six_percent.to_i

        supp_ins =
          profile&.supplementary_insurance.to_i

        hourly_rate =
          if profile&.hourly_rate.present?
            profile.hourly_rate
          else
            BigDecimal("0")
          end

        seniority_base_adj =
          adjust_by_month_days.call(
            seniority_base_profile
          )

        monthly_seniority_adj =
          adjust_by_month_days.call(
            monthly_seniority_profile
          )

        insurance_base_sum =
          seniority_base_adj +
          marriage_allowance +
          housing_allowance +
          monthly_seniority_adj

        insurance_value =
          (
            insurance_base_sum.to_f * 0.07
          ).round

        archive.assign_attributes(
          accounting_confirmed: true,
          accounting_confirmed_at: now,

          seniority_base:
            seniority_base_adj,

          monthly_seniority_base:
            monthly_seniority_adj,

          housing_allowance:
            housing_allowance,

          food_allowance:
            food_allowance,

          marriage_allowance:
            marriage_allowance,

          child_allowance:
            child_allowance,

          total_salary:
            total_salary,

          hourly_rate:
            hourly_rate,

          loan_installment:
            loan_installment,

          fund_three_percent:
            fund_three_percent,

          fund_six_percent:
            fund_six_percent,

          supplementary_insurance:
            supp_ins,

          insurance:
            insurance_value
        )

        archive.save!(
          validate: false
        )
      end
    end

    redirect_to accounting_review_salary_archives_path(
      month_id: @shamsi_month.id
    ),
    notice:
      "تأیید حسابداری ثبت شد و محاسبات (تعدیل ۲۹/۳۰/۳۱ + بیمه) داخل آرشیو ذخیره شد."
  end

  def accounting_update_adjustments
    authorize_accounting_review!

    allowed_archives =
      SalaryArchive.where(
        shamsi_month_id:
          @shamsi_month.id
      )

    archives_params =
      params[:archives] || {}

    SalaryArchive.transaction do
      archives_params.each do |archive_id, attrs|
        a =
          allowed_archives.find_by(
            id: archive_id
          )

        next unless a

        attrs ||= {}

        a.update!(
          acc_add_1_title:
            attrs[:acc_add_1_title]
              .to_s.strip.presence,

          acc_add_1_amount:
            attrs[:acc_add_1_amount].to_i,

          acc_add_2_title:
            attrs[:acc_add_2_title]
              .to_s.strip.presence,

          acc_add_2_amount:
            attrs[:acc_add_2_amount].to_i,

          acc_ded_1_title:
            attrs[:acc_ded_1_title]
              .to_s.strip.presence,

          acc_ded_1_amount:
            attrs[:acc_ded_1_amount].to_i,

          acc_ded_2_title:
            attrs[:acc_ded_2_title]
              .to_s.strip.presence,

          acc_ded_2_amount:
            attrs[:acc_ded_2_amount].to_i,

          legal_add_1_title:
            attrs[:legal_add_1_title]
              .to_s.strip.presence,

          legal_add_1_amount:
            attrs[:legal_add_1_amount].to_i,

          legal_add_2_title:
            attrs[:legal_add_2_title]
              .to_s.strip.presence,

          legal_add_2_amount:
            attrs[:legal_add_2_amount].to_i,

          legal_ded_1_title:
            attrs[:legal_ded_1_title]
              .to_s.strip.presence,

          legal_ded_1_amount:
            attrs[:legal_ded_1_amount].to_i,

          legal_ded_2_title:
            attrs[:legal_ded_2_title]
              .to_s.strip.presence,

          legal_ded_2_amount:
            attrs[:legal_ded_2_amount].to_i,

          legal_ded_2_amount:
            attrs[:legal_ded_2_amount].to_i
        )
      end
    end

    redirect_to accounting_review_salary_archives_path(
      month_id: @shamsi_month.id
    ),
    notice:
      "آیتم‌های حسابداری (قسمت اول و دوم) ذخیره شد."
  end

def payslips
    authorize_hr_review!

    scope =
      SalaryArchive
        .includes(:user)
        .where(
          shamsi_month_id:
            @shamsi_month.id
        )
        .joins(user: :salary_profile)

    @archives =
      scope.order("user_id ASC")

    respond_to do |format|
      format.html

      format.csv do
        month_days =
          (
            @shamsi_month.end_at.to_date -
            @shamsi_month.start_at.to_date
          ).to_i + 1

        adjust_30_to_month =
          lambda do |monthly_amount|
            (
              (monthly_amount.to_f / 30.0) *
              month_days
            ).round
          end

        hours =
          lambda do |mins|
            (
              mins.to_i / 60.0
            ).round(2)
          end

        helpers = view_context

        money_ui =
          lambda do |n|
            helpers.number_with_delimiter(
              n.to_i
            )
          end

        num_ui =
          lambda do |n|
            helpers.number_with_delimiter(n)
          end

        bom = "\uFEFF"

        csv_data =
          bom +
          CSV.generate(headers: true) do |csv|

            csv << [
              "نام ماه",
              "شناسه کاربر",
              "نام کاربر",

              "پرداختی اول (UI)",
              "پرداختی دوم (UI)",

              "حقوق پایه (UI)",
              "پایه سنوات (UI)",
              "حق مسکن و خواروبار (UI)",
              "ایاب و ذهاب (UI)",
              "حق تأهل (UI)",
              "حق اولاد (UI)",

              "حقوق قانونی (UI)",
              "بیمه (۷٪) (UI)",

              "حقوق مصوب (#{month_days} روز) (UI)",
              "مجموع ساعات کاری",
              "نرخ ساعتی (UI)",
              "ساعت اضافه‌کاری",
              "ساعت کسری",

              "قسط وام (UI)",
              "ذخیره ۳٪ (UI)",
              "ذخیره ۶٪ (UI)",
              "کسر کسری (ساعت × نرخ × ۲) (UI)",
              "افزودن اضافه‌کاری (×۱.۴) (UI)",

              "بیمه تکمیلی (UI)",

              "افزایشی حسابداری ۱ - عنوان",
              "افزایشی حسابداری ۱ - مبلغ (UI)",

              "افزایشی حسابداری ۲ - عنوان",
              "افزایشی حسابداری ۲ - مبلغ (UI)",

              "کاهشی حسابداری ۱ - عنوان",
              "کاهشی حسابداری ۱ - مبلغ (UI)",

              "کاهشی حسابداری ۲ - عنوان",
              "کاهشی حسابداری ۲ - مبلغ (UI)",

              "جمع افزایشی حسابداری (UI)",
              "جمع کسورات حسابداری (UI)",
              "خالص آیتم‌های حسابداری (UI)",

              # =========================
              # Mission
              # =========================
              "ماموریت - ساعات کاری",
              "ماموریت - ساعات غیرکاری",
              "ماموریت - ساعات کاری روز تعطیل",

              "ماموریت - مبلغ ساعات کاری (UI)",
              "ماموریت - مبلغ ساعات غیرکاری (UI)",
              "ماموریت - مبلغ ساعات کاری روز تعطیل (UI)",
              "ماموریت - مجموع مبلغ ماموریت (UI)"
            ]

            @archives.each do |archive|
              user = archive.user

              base_salary =
                archive.seniority_base.to_i

              paye_sanavat =
                archive.monthly_seniority_base.to_i

              marriage =
                archive.marriage_allowance.to_i

              child =
                archive.child_allowance.to_i

              housing =
                archive.housing_allowance.to_i

              food =
                archive.food_allowance.to_i

              legal_salary =
                base_salary +
                marriage +
                housing +
                paye_sanavat +
                child

              insurance =
                archive.insurance.to_i

              payment_1 =
                legal_salary - insurance

              total_salary_adj =
                adjust_30_to_month.call(
                  archive.total_salary.to_i
                )

              total_work_h =
                hours.call(
                  archive.total_work_minutes
                )

              overtime_mins =
                if archive.manual_overtime_minutes.to_i != 0
                  archive.manual_overtime_minutes.to_i
                else
                  archive.overtime_minutes.to_i
                end

              deficit_mins =
                if archive.no_dificit == true
                  0
                elsif archive.manual_deficit_minutes.to_i != 0
                  archive.manual_deficit_minutes.to_i
                else
                  archive.deficit_minutes.to_i
                end

              overtime_h =
                hours.call(overtime_mins)

              deficit_h =
                hours.call(deficit_mins)

              hourly_rate =
                if archive.hourly_rate.present?
                  archive.hourly_rate.to_f
                else
                  0.0
                end

              loan =
                archive.loan_installment.to_i

              fund3 =
                archive.fund_three_percent.to_i

              fund6 =
                archive.fund_six_percent.to_i

              overtime_pay =
                overtime_h *
                hourly_rate *
                1.4

              deficit_deduction =
                if archive.no_dificit == true
                  0
                else
                  deficit_h *
                    hourly_rate
                end

              # =========================================================
              # Accounting additions / deductions
              # =========================================================

              acc_add_1_title =
                archive.respond_to?(
                  :acc_add_1_title
                ) ?
                  archive.acc_add_1_title
                    .to_s.strip :
                  ""

              acc_add_2_title =
                archive.respond_to?(
                  :acc_add_2_title
                ) ?
                  archive.acc_add_2_title
                    .to_s.strip :
                  ""

              acc_ded_1_title =
                archive.respond_to?(
                  :acc_ded_1_title
                ) ?
                  archive.acc_ded_1_title
                    .to_s.strip :
                  ""

              acc_ded_2_title =
                archive.respond_to?(
                  :acc_ded_2_title
                ) ?
                  archive.acc_ded_2_title
                    .to_s.strip :
                  ""

              acc_add_1_amount =
                archive.respond_to?(
                  :acc_add_1_amount
                ) ?
                  archive.acc_add_1_amount.to_i :
                  0

              acc_add_2_amount =
                archive.respond_to?(
                  :acc_add_2_amount
                ) ?
                  archive.acc_add_2_amount.to_i :
                  0

              acc_ded_1_amount =
                archive.respond_to?(
                  :acc_ded_1_amount
                ) ?
                  archive.acc_ded_1_amount.to_i :
                  0

              acc_ded_2_amount =
                archive.respond_to?(
                  :acc_ded_2_amount
                ) ?
                  archive.acc_ded_2_amount.to_i :
                  0

              supplementary_insurance =
                archive.respond_to?(
                  :supplementary_insurance
                ) ?
                  archive.supplementary_insurance.to_i :
                  0

              acc_add_total =
                acc_add_1_amount +
                acc_add_2_amount

              acc_ded_total =
                acc_ded_1_amount +
                acc_ded_2_amount +
                supplementary_insurance

              acc_net =
                acc_add_total -
                acc_ded_total

              # =========================================================
              # Mission
              # =========================================================

              mission_working_minutes =
                archive.respond_to?(
                  :mission_working_minutes
                ) ?
                  archive.mission_working_minutes.to_i :
                  0

              mission_non_working_minutes =
                archive.respond_to?(
                  :mission_non_working_minutes
                ) ?
                  archive.mission_non_working_minutes.to_i :
                  0

              mission_holiday_working_minutes =
                archive.respond_to?(
                  :mission_holiday_working_minutes
                ) ?
                  archive.mission_holiday_working_minutes.to_i :
                  0

              mission_working_h =
                hours.call(
                  mission_working_minutes
                )

              mission_non_working_h =
                hours.call(
                  mission_non_working_minutes
                )

              mission_holiday_working_h =
                hours.call(
                  mission_holiday_working_minutes
                )

              mission_working_pay =
                archive.respond_to?(
                  :mission_working_pay
                ) ?
                  archive.mission_working_pay.to_f :
                  0.0

              mission_non_working_pay =
                archive.respond_to?(
                  :mission_non_working_pay
                ) ?
                  archive.mission_non_working_pay.to_f :
                  0.0

              mission_holiday_working_pay =
                archive.respond_to?(
                  :mission_holiday_working_pay
                ) ?
                  archive.mission_holiday_working_pay.to_f :
                  0.0

              mission_total_pay =
                archive.respond_to?(
                  :mission_total_pay
                ) ?
                  archive.mission_total_pay.to_f :
                  0.0

              # =========================================================
              # Payment 2
              # =========================================================

              payment_2 = (
                total_salary_adj -
                fund6 -
                fund3 -
                loan -
                deficit_deduction +
                overtime_pay +
                acc_add_total -
                acc_ded_total +
                food
              ).round

              overtime_pay_ui =
                money_ui.call(
                  overtime_pay.round
                )

              deficit_deduction_ui =
                money_ui.call(
                  deficit_deduction.round
                )

              csv << [
                @shamsi_month.name,
                archive.user_id,
                user&.name.to_s,

                money_ui.call(payment_1),
                money_ui.call(payment_2),

                money_ui.call(base_salary),
                money_ui.call(paye_sanavat),
                money_ui.call(housing),
                money_ui.call(food),
                money_ui.call(marriage),
                money_ui.call(child),

                money_ui.call(legal_salary),
                money_ui.call(insurance),

                money_ui.call(total_salary_adj),
                total_work_h,
                num_ui.call(
                  hourly_rate.round(2)
                ),
                overtime_h,
                deficit_h,

                money_ui.call(loan),
                money_ui.call(fund3),
                money_ui.call(fund6),
                deficit_deduction_ui,
                overtime_pay_ui,

                money_ui.call(
                  supplementary_insurance
                ),

                acc_add_1_title,
                money_ui.call(
                  acc_add_1_amount
                ),

                acc_add_2_title,
                money_ui.call(
                  acc_add_2_amount
                ),

                acc_ded_1_title,
                money_ui.call(
                  acc_ded_1_amount
                ),

                acc_ded_2_title,
                money_ui.call(
                  acc_ded_2_amount
                ),

                money_ui.call(acc_add_total),
                money_ui.call(acc_ded_total),
                money_ui.call(acc_net),

                # =======================================================
                # Mission values
                # =======================================================

                mission_working_h,
                mission_non_working_h,
                mission_holiday_working_h,

                money_ui.call(
                  mission_working_pay.round
                ),

                money_ui.call(
                  mission_non_working_pay.round
                ),

                money_ui.call(
                  mission_holiday_working_pay.round
                ),

                money_ui.call(
                  mission_total_pay.round
                )
              ]
            end
          end

        filename =
          "payslips-#{@shamsi_month.id}-#{@shamsi_month.name}.csv"
            .gsub(/[^\w\-.]/, "_")

        send_data(
          csv_data,
          filename: filename,
          type: "text/csv; charset=utf-8"
        )
      end
    end
  end
  private

  def set_month
    @shamsi_month =
      ShamsiMonth.find(
        params[:month_id]
      )
  end

  def fetch_global_remote_dates(shamsi_month)
    start_d =
      shamsi_month.start_at.to_date

    end_d =
      shamsi_month.end_at.to_date

    ShamsiMonthRemoteDay
      .where(
        shamsi_month_id:
          shamsi_month.id,
        day: start_d..end_d
      )
      .pluck(:day)
      .map(&:to_date)
      .to_set
  end

  def hours_to_minutes(val)
    return 0 if val.blank?

    h = val.to_f

    h =
      (h * 4).round / 4.0

    (h * 60).round
  end

  # ============================================================
  # REQUIRED WORKING TIME
  # ============================================================

  def required_minutes_for(
    date,
    off_dates:
  )
    return 0 if off_dates.include?(date)

    return 240 if date.thursday?

    480
  end

  # ============================================================
  # FLEXIBLE ATTENDANCE WINDOWS
  # ============================================================

  def attendance_boundaries_for(date)
    arrival_start =
      date.in_time_zone.change(
        hour: 8,
        min: 30,
        sec: 0
      )

    arrival_flexible_end =
      date.in_time_zone.change(
        hour: 9,
        min: 15,
        sec: 0
      )

    departure_start =
      if date.thursday?
        date.in_time_zone.change(
          hour: 12,
          min: 30,
          sec: 0
        )
      else
        date.in_time_zone.change(
          hour: 16,
          min: 30,
          sec: 0
        )
      end

    departure_flexible_end =
      if date.thursday?
        date.in_time_zone.change(
          hour: 13,
          min: 15,
          sec: 0
        )
      else
        date.in_time_zone.change(
          hour: 17,
          min: 15,
          sec: 0
        )
      end

    [
      arrival_start,
      arrival_flexible_end,
      departure_start,
      departure_flexible_end
    ]
  end

  def working_interval_for(date)
    arrival_start,
      _arrival_flexible_end,
      departure_start,
      _departure_flexible_end =
      attendance_boundaries_for(date)

    [
      arrival_start,
      departure_start
    ]
  end

  def interval_minutes(
    start_at,
    end_at
  )
    return 0 if start_at.blank?
    return 0 if end_at.blank?
    return 0 if end_at <= start_at

    (
      (end_at - start_at) / 60.0
    ).round
  end

  def merged_interval_minutes(intervals)
    normalized =
      intervals
        .select do |from, to|
          from.present? &&
            to.present? &&
            to > from
        end
        .sort_by(&:first)

    return 0 if normalized.empty?

    merged = []

    normalized.each do |from, to|
      if merged.empty? ||
         from > merged.last[1]

        merged << [from, to]
      else
        merged.last[1] =
          [
            merged.last[1],
            to
          ].max
      end
    end

    merged.sum do |from, to|
      interval_minutes(
        from,
        to
      )
    end
  end

  def clipped_interval(
    start_at,
    end_at,
    range_start,
    range_end
  )
    from =
      [
        start_at,
        range_start
      ].max

    to =
      [
        end_at,
        range_end
      ].min

    return nil unless to > from

    [from, to]
  end

  # ============================================================
  # MISSION CALCULATION
  # ============================================================

  def mission_working_intervals_for(
    missions,
    date
  )
    return [] if missions.blank?

    work_start,
      work_end =
      working_interval_for(date)

    missions.filter_map do |mission|
      clipped_interval(
        mission.start_at,
        mission.end_at,
        work_start,
        work_end
      )
    end
  end

  def mission_hours_for_date(
    missions,
    date
  )
    return {
      working_minutes: 0,
      non_working_minutes: 0
    } if missions.blank?

    day_start =
      date.beginning_of_day

    day_end =
      (date + 1.day).beginning_of_day

    total_intervals =
      missions.filter_map do |mission|
        clipped_interval(
          mission.start_at,
          mission.end_at,
          day_start,
          day_end
        )
      end

    working_intervals =
      mission_working_intervals_for(
        missions,
        date
      )

    {
      working_minutes:
        merged_interval_minutes(
          working_intervals
        ),

      non_working_minutes:
        [
          merged_interval_minutes(
            total_intervals
          ) -
          merged_interval_minutes(
            working_intervals
          ),
          0
        ].max
    }
  end

  def build_mission_map(user_ids)
    missions =
      Mission
        .where(user_id: user_ids)
        .where(
          "start_at <= ? AND end_at >= ?",
          @shamsi_month.end_at.end_of_day,
          @shamsi_month.start_at.beginning_of_day
        )
        .select(
          :id,
          :user_id,
          :start_at,
          :end_at,
          :mission_type
        )

    map =
      Hash.new do |h, k|
        h[k] = {}
      end

    missions.each do |mission|
      from =
        [
          mission.start_at.to_date,
          @shamsi_month.start_at.to_date
        ].max

      to =
        [
          mission.end_at.to_date,
          @shamsi_month.end_at.to_date
        ].min

      (from..to).each do |date|
        map[mission.user_id][date] ||= []
        map[mission.user_id][date] << mission
      end
    end

    map
  end

  # ============================================================
  # VACATION INTERVAL MAP
  # ============================================================

  def build_vacation_intervals_map(user_ids)
    start_t =
      @shamsi_month.start_at
        .beginning_of_day

    end_t =
      @shamsi_month.end_at
        .end_of_day

    vacations =
      Vacation
        .where(user_id: user_ids)
        .where(
          "start_at <= ? AND end_at >= ?",
          end_t,
          start_t
        )
        .select(
          :id,
          :user_id,
          :hourly,
          :start_at,
          :end_at,
          :confirm
        )

    map =
      Hash.new do |h, k|
        h[k] = {}
      end

    vacations.each do |vacation|
      next if vacation.confirm == false

      from =
        [
          vacation.start_at.to_date,
          @shamsi_month.start_at.to_date
        ].max

      to =
        [
          vacation.end_at.to_date,
          @shamsi_month.end_at.to_date
        ].min

      (from..to).each do |date|
        map[vacation.user_id][date] ||= []

        day_start =
          date.beginning_of_day

        day_end =
          (date + 1.day).beginning_of_day

        if vacation.hourly?
          interval =
            clipped_interval(
              vacation.start_at,
              vacation.end_at,
              day_start,
              day_end
            )

          map[vacation.user_id][date] << interval if interval
        else
          map[vacation.user_id][date] << :daily
        end
      end
    end

    map
  end

  def vacation_working_intervals_for(
    vacation_intervals,
    date
  )
    return [] if vacation_intervals.blank?

    work_start,
      work_end =
      working_interval_for(date)

    vacation_intervals.filter_map do |item|
      next if item == :daily

      clipped_interval(
        item[0],
        item[1],
        work_start,
        work_end
      )
    end
  end

  # ============================================================
  # VACATION INFO
  # ============================================================

  def build_vacation_info_map(user_ids)
    start_t =
      @shamsi_month.start_at
        .beginning_of_day

    end_t =
      @shamsi_month.end_at
        .end_of_day

    vacations =
      Vacation
        .where(user_id: user_ids)
        .where(
          "start_at <= ? AND end_at >= ?",
          end_t,
          start_t
        )
        .select(
          :id,
          :user_id,
          :hourly,
          :start_at,
          :end_at,
          :confirm,
          :details,
          :comment
        )

    map =
      Hash.new do |h, k|
        h[k] = {}
      end

    vacations.each do |vacation|
      confirmed =
        vacation.confirm == true

      if vacation.hourly?
        from =
          [
            vacation.start_at.to_date,
            @shamsi_month.start_at.to_date
          ].max

        to =
          [
            vacation.end_at.to_date,
            @shamsi_month.end_at.to_date
          ].min

        (from..to).each do |date|
          day_start =
            [
              vacation.start_at,
              date.beginning_of_day
            ].max

          day_end =
            [
              vacation.end_at,
              (date + 1.day).beginning_of_day
            ].min

          minutes =
            interval_minutes(
              day_start,
              day_end
            )

          next unless minutes > 0

          map[vacation.user_id][date] = {
            vacation_id:
              vacation.id,

            kind:
              :hourly,

            minutes:
              minutes,

            confirmed:
              confirmed,

            details:
              vacation.details.to_s,

            comment:
              vacation.comment.to_s
          }
        end
      else
        from =
          [
            vacation.start_at.to_date,
            @shamsi_month.start_at.to_date
          ].max

        to =
          [
            vacation.end_at.to_date,
            @shamsi_month.end_at.to_date
          ].min

        (from..to).each do |date|
          map[vacation.user_id][date] = {
            vacation_id:
              vacation.id,

            kind:
              :daily,

            minutes:
              0,

            confirmed:
              confirmed,

            details:
              vacation.details.to_s,

            comment:
              vacation.comment.to_s
          }
        end
      end
    end

    map
  end

  # ============================================================
  # REVIEW DATA
  # ============================================================

  def load_review_data(user_ids)
    remote_days =
      RemoteDay.where(
        user_id: user_ids,
        date:
          @shamsi_month.start_at.to_date..
          @shamsi_month.end_at.to_date
      )

    @remote_days_by_user_date =
      remote_days
        .group_by(&:user_id)
        .transform_values do |rows|
          rows.index_by(&:date)
        end

    overtime_entries =
      OvertimeEntry.where(
        user_id: user_ids,
        date:
          @shamsi_month.start_at.to_date..
          @shamsi_month.end_at.to_date
      )

    @overtime_by_user_date =
      overtime_entries
        .group_by(&:user_id)
        .transform_values do |rows|
          rows.group_by(&:date)
        end

    manual_entries =
      ManualEntry.where(
        user_id: user_ids,
        occurred_at:
          @shamsi_month.start_at
            .beginning_of_day..
          @shamsi_month.end_at
            .end_of_day
      )

    @manual_by_user_date =
      build_manual_map(
        manual_entries
      )

    @off_dates =
      @shamsi_month.off_dates.to_set

    @global_remote_dates =
      fetch_global_remote_dates(
        @shamsi_month
      )

    @weekday_fa =
      %w[
        یکشنبه
        دوشنبه
        سه‌شنبه
        چهارشنبه
        پنجشنبه
        جمعه
        شنبه
      ]

    @pay_type_by_user_id =
      SalaryProfile
        .where(user_id: user_ids)
        .pluck(:user_id, :pay_type)
        .to_h
        .transform_values do |value|
          {
            "fixed" =>
              "پرداخت ثابت",

            "hourly" =>
              "محاسبه کامل",

            "fixed_with_overtime" =>
              "ثابت + اضافه/کسری"
          }[value.to_s] ||
            "نامشخص"
        end

    @vacation_info_by_user_date =
      build_vacation_info_map(
        user_ids
      )

    @mission_by_user_date =
      build_mission_map(
        user_ids
      )

    @mission_payroll_by_user_id =
      mission_payroll_by_user_ids(
        user_ids,
        @mission_by_user_date,
        @off_dates
      )

    @fmt_hours =
      lambda do |minutes|
        m = minutes.to_i
        return 0 if m <= 0

        q =
          (m / 15.0).round

        q * 0.25
      end
  end

  # ============================================================
  # MISSION PAYROLL
  # ============================================================

  def mission_payroll_by_user_ids(
    user_ids,
    mission_map,
    off_dates
  )
    users =
      User
        .where(id: user_ids)
        .includes(:salary_profile)
        .index_by(&:id)

    user_ids.index_with do |user_id|
      missions_by_date =
        mission_map[user_id] || {}

      working_normal_minutes = 0
      non_working_minutes = 0
      working_holiday_minutes = 0

      missions_by_date.each do |date, missions|
        info =
          mission_hours_for_date(
            missions,
            date
          )

        working_minutes =
          info[:working_minutes].to_i

        non_working =
          info[:non_working_minutes].to_i

        non_working_minutes +=
          non_working

        if off_dates.include?(date) ||
           date.friday?

          working_holiday_minutes +=
            working_minutes
        else
          working_normal_minutes +=
            working_minutes
        end
      end

      hourly_rate =
        users[user_id]
          &.salary_profile
          &.hourly_rate
          .to_d || 0.to_d

      normal_pay =
        (
          working_normal_minutes / 60.0 *
          hourly_rate
        ).round(2)

      non_working_pay =
        (
          non_working_minutes / 60.0 *
          hourly_rate *
          1.4
        ).round(2)

      holiday_pay =
        (
          working_holiday_minutes / 60.0 *
          hourly_rate *
          2
        ).round(2)

      {
        working_minutes:
          working_normal_minutes,

        non_working_minutes:
          non_working_minutes,

        holiday_working_minutes:
          working_holiday_minutes,

        working_pay:
          normal_pay,

        non_working_pay:
          non_working_pay,

        holiday_working_pay:
          holiday_pay,

        total_pay:
          (
            normal_pay +
            non_working_pay +
            holiday_pay
          ).round(2)
      }
    end
  end

  def recalculate_mission_payroll_for_archives(
    archives
  )
    archives =
      archives.to_a

    return if archives.empty?

    user_ids =
      archives.map(&:user_id).uniq

    mission_map =
      build_mission_map(
        user_ids
      )

    payroll_map =
      mission_payroll_by_user_ids(
        user_ids,
        mission_map,
        @shamsi_month.off_dates.to_set
      )

    archives.each do |archive|
      values =
        payroll_map[archive.user_id] || {
          working_minutes: 0,
          non_working_minutes: 0,
          holiday_working_minutes: 0,
          working_pay: 0,
          non_working_pay: 0,
          holiday_working_pay: 0,
          total_pay: 0
        }

      archive.update!(
        mission_working_minutes:
          values[:working_minutes],

        mission_non_working_minutes:
          values[:non_working_minutes],

        mission_holiday_working_minutes:
          values[:holiday_working_minutes],

        mission_working_pay:
          values[:working_pay],

        mission_non_working_pay:
          values[:non_working_pay],

        mission_holiday_working_pay:
          values[:holiday_working_pay],

        mission_total_pay:
          values[:total_pay]
      )
    end
  end

  # ============================================================
  # OVERTIME / MANUAL ENTRIES
  # ============================================================

  def build_overtime_map(user_ids)
    overtime_entries =
      OvertimeEntry.where(
        user_id: user_ids,
        date:
          @shamsi_month.start_at.to_date..
          @shamsi_month.end_at.to_date
      )

    overtime_entries
      .group_by(&:user_id)
      .transform_values do |rows|
        rows.group_by(&:date)
      end
  end

  def outside_system_overtime_minutes(
    ot_map,
    user_id,
    date
  )
    list =
      (
        ot_map[user_id] || {}
      )[date] || []

    list =
      list.select do |ot|
        ot.confirmed == true
      end

    list.sum do |ot|
      (
        ot.hours.to_f * 60
      ).round
    end
  end

  def build_manual_map(manual_entries)
    map =
      Hash.new do |h, k|
        h[k] = {}
      end

    manual_entries.each do |m|
      d =
        m.occurred_at.to_date

      map[m.user_id][d] ||= {}

      if m.is_entry
        map[m.user_id][d][:entry] = m
      else
        map[m.user_id][d][:exit] = m
      end
    end

    map
  end

  # ============================================================
  # AUTHORIZATION
  # ============================================================

  def authorize_hr_review!
    allowed =
      (
        current_user.procurement? &&
        current_user.is_manager
      ) ||

      (
        current_user.hr? &&
        current_user.is_manager
      ) ||

      (
        current_user.accounting? &&
        current_user.is_manager
      ) ||

      current_user.id == 17 ||
      current_user.ceo? ||
      current_user.cob? ||
      current_user.admin?

    head :forbidden unless allowed
  end

  def authorize_hr_confirm!
    head :forbidden unless current_user.id == 17
  end

  def authorize_accounting_review!
    allowed =
      (
        current_user.accounting? &&
        current_user.is_manager
      ) ||
      current_user.admin?

    head :forbidden unless allowed
  end

  # ============================================================
  # TIME PARSING
  # ============================================================

  def parse_hhmm_to_time(
    date,
    value
  )
    normalized =
      normalize_hhmm(value)

    return nil if normalized.blank?

    hour, minute =
      normalized.split(":")
        .map(&:to_i)

    date.in_time_zone.change(
      hour: hour,
      min: minute,
      sec: 0
    )
  end

  TIME_RE =
    /\A([01]?\d|2[0-3]):([0-5]?\d)\z/

  def normalize_hhmm(val)
    s =
      val.to_s.strip

    return nil if s.blank?

    m =
      TIME_RE.match(s)

    return nil unless m

    hh =
      m[1].to_i

    mm =
      m[2].to_i

    format(
      "%02d:%02d",
      hh,
      mm
    )
  end

  # ============================================================
  # DAY RECALCULATION
  # ============================================================

  def recalculate_salary_archive_day!(
    day:,
    vac_map:,
    vacation_intervals_map:,
    ot_map:,
    mission_map:,
    off_dates:,
    global_remote_dates:
  )
    user_id =
      day.salary_archive.user_id

    date =
      day.work_date

    # ------------------------------------------------------------
    # 1. DAILY CONFIRMED VACATION
    # ------------------------------------------------------------

    vinfo =
      (vac_map[user_id] || {})[date]

    daily_confirmed =
      vinfo.present? &&
      vinfo[:kind] == :daily &&
      vinfo[:confirmed] == true

    if daily_confirmed
      day.update!(
        first_in_at: nil,
        last_out_at: nil,
        overtime_minutes: 0,
        deficit_minutes: 0
      )

      return
    end

    # ------------------------------------------------------------
    # 2. GLOBAL REMOTE DAY
    # ------------------------------------------------------------

    if global_remote_dates.include?(date)
      confirmed_ot =
        outside_system_overtime_minutes(
          ot_map,
          user_id,
          date
        )

      day.update!(
        deficit_minutes: 0,
        overtime_minutes: confirmed_ot
      )

      return
    end

    # ------------------------------------------------------------
    # 3. REMOTE DAY
    # ------------------------------------------------------------

    remote_day =
      RemoteDay.find_by(
        user_id: user_id,
        date: date
      )

    if remote_day &&
       remote_day.confirmed == false

      required =
        required_minutes_for(
          date,
          off_dates: off_dates
        )

      day.update!(
        overtime_minutes: 0,
        deficit_minutes: required
      )

      return
    end

    if remote_day &&
       remote_day.confirmed == true

      confirmed_ot =
        outside_system_overtime_minutes(
          ot_map,
          user_id,
          date
        )

      day.update!(
        deficit_minutes: 0,
        overtime_minutes: confirmed_ot
      )

      return
    end

    # ------------------------------------------------------------
    # 4. NORMAL ATTENDANCE CALCULATION
    # ------------------------------------------------------------

    deficit_minutes,
      base_overtime_minutes =
      compute_deficit_and_base_overtime_minutes(
        day: day,
        user_id: user_id,
        date: date,
        off_dates: off_dates,
        vac_map: vac_map,
        mission_map: mission_map,
        vacation_intervals_map:
          vacation_intervals_map
      )

    # ------------------------------------------------------------
    # 5. EXTERNAL CONFIRMED OVERTIME
    # ------------------------------------------------------------

    confirmed_ot_minutes =
      outside_system_overtime_minutes(
        ot_map,
        user_id,
        date
      )

    final_overtime =
      base_overtime_minutes +
      confirmed_ot_minutes

    day.update!(
      deficit_minutes:
        deficit_minutes,

      overtime_minutes:
        final_overtime
    )
  end

  # ============================================================
  # FLEXIBLE ATTENDANCE CALCULATION
  #
  # NORMAL DAY
  #
  # Arrival:
  #   08:30 -> 09:15
  #
  # Departure:
  #   16:30 -> 17:15
  #
  # Example:
  #
  #   10:00 -> 20:00
  #
  #   deficit = 45
  #   overtime = 165
  #
  # THURSDAY
  #
  # Arrival:
  #   08:30 -> 09:15
  #
  # Departure:
  #   12:30 -> 13:15
  #
  # FRIDAY / OFF DAY
  #
  # There is NO required attendance deficit.
  #
  # The COMPLETE actual attendance interval is overtime.
  #
  # Examples:
  #
  #   Friday 08:30 -> 16:30
  #   overtime = 480
  #
  #   Friday 10:00 -> 18:00
  #   overtime = 480
  #
  #   Off day 09:00 -> 14:00
  #   overtime = 300
  #
  # Confirmed OvertimeEntry is still added separately.
  #
  # Mission does NOT create attendance overtime.
  # ============================================================

  def compute_deficit_and_base_overtime_minutes(
    day:,
    user_id:,
    date:,
    off_dates:,
    vac_map:,
    mission_map: {},
    vacation_intervals_map: nil
  )
    # ------------------------------------------------------------
    # Parse attendance FIRST.
    #
    # This must happen BEFORE checking required_minutes because
    # Friday/off days have required_minutes = 0 but their actual
    # attendance must still become overtime.
    # ------------------------------------------------------------

    in_time = nil
    out_time = nil

    if day.first_in_at.present?
      in_time =
        parse_hhmm_to_time(
          date,
          day.first_in_at
        )
    end

    if day.last_out_at.present?
      out_time =
        parse_hhmm_to_time(
          date,
          day.last_out_at
        )
    end

    if out_time &&
       in_time &&
       out_time < in_time

      # Preserve support for overnight attendance.
      out_time += 1.day
    end

    # ------------------------------------------------------------
    # FRIDAY / OFF DAY
    #
    # Complete actual attendance is overtime.
    #
    # IMPORTANT:
    # We do NOT use the flexible 17:15 boundary here.
    #
    # Friday:
    #   08:30 -> 16:30 = 480 OT
    #
    # Off day:
    #   10:00 -> 18:00 = 480 OT
    #
    # There is no attendance deficit.
    # ------------------------------------------------------------

    if off_dates.include?(date) ||
       date.friday?

      base_overtime_minutes = 0

      if in_time.present? &&
         out_time.present?

        base_overtime_minutes =
          interval_minutes(
            in_time,
            out_time
          )
      end

      # No required attendance on these days.
      #
      # Any actual attendance is overtime.
      #
      # Manual adjustment remains an additional working-time
      # credit, but there is no deficit to reduce here.
      return [
        0,
        base_overtime_minutes
      ]
    end

    # ------------------------------------------------------------
    # NORMAL / THURSDAY REQUIRED TIME
    # ------------------------------------------------------------

    required_minutes =
      required_minutes_for(
        date,
        off_dates: off_dates
      )

    return [0, 0] if required_minutes <= 0

    # ------------------------------------------------------------
    # FLEXIBLE BOUNDARIES
    # ------------------------------------------------------------

    arrival_start,
      arrival_flexible_end,
      departure_start,
      departure_flexible_end =
      attendance_boundaries_for(date)

    # ------------------------------------------------------------
    # ATTENDANCE DEFICIT
    # ------------------------------------------------------------

    attendance_deficit_intervals = []

    if in_time.present? && out_time.present?

      # ----------------------------------------
      # Late arrival
      #
      # 09:15 is the end of flexibility.
      # After that every minute is deficit.
      # ----------------------------------------

      if in_time > arrival_flexible_end
        attendance_deficit_intervals << [
          arrival_flexible_end,
          in_time
        ]
      end

      # ----------------------------------------
      # Early departure
      #
      # 16:30 normal
      # 12:30 Thursday
      #
      # Before this point is deficit.
      # ----------------------------------------

      if out_time < departure_start
        attendance_deficit_intervals << [
          out_time,
          departure_start
        ]
      end

    else
      # No complete attendance.
      #
      # Credit can still come from confirmed
      # vacation or mission below.
      # ----------------------------------------------------------

      attendance_deficit_intervals << [
        arrival_flexible_end,
        departure_start
      ]
    end

    # ------------------------------------------------------------
    # ATTENDANCE OVERTIME
    #
    # Only time after 17:15 / 13:15 counts as normal attendance OT.
    #
    # Example:
    #
    # 10:00 -> 20:00
    #
    # 20:00 - 17:15 = 165 OT
    #
    # The 45-minute late arrival deficit remains independent.
    # ------------------------------------------------------------

    base_overtime_minutes = 0

    if out_time.present? &&
       out_time > departure_flexible_end

      base_overtime_minutes =
        interval_minutes(
          departure_flexible_end,
          out_time
        )
    end

    # ------------------------------------------------------------
    # VACATION / MISSION COVERAGE
    # ------------------------------------------------------------

    coverage_intervals = []

    vinfo =
      (vac_map[user_id] || {})[date]

    hourly_confirmed =
      vinfo.present? &&
      vinfo[:kind] == :hourly &&
      vinfo[:confirmed] == true

    if hourly_confirmed
      vacation_intervals =
        (
          vacation_intervals_map[user_id] || {}
        )[date] || []

      vacation_working_intervals_for(
        vacation_intervals,
        date
      ).each do |interval|

        coverage_intervals << interval
      end
    end

    missions =
      (
        mission_map[user_id] || {}
      )[date] || []

    mission_working_intervals_for(
      missions,
      date
    ).each do |interval|

      coverage_intervals << interval
    end

    # ------------------------------------------------------------
    # RAW DEFICIT
    # ------------------------------------------------------------

    raw_deficit_minutes =
      merged_interval_minutes(
        attendance_deficit_intervals
      )

    # ------------------------------------------------------------
    # COVER ONLY THE ACTUAL DEFICIT PERIODS
    # ------------------------------------------------------------

    covered_deficit_intervals = []

    attendance_deficit_intervals.each do |deficit_from, deficit_to|
      coverage_intervals.each do |cover_from, cover_to|

        clipped =
          clipped_interval(
            cover_from,
            cover_to,
            deficit_from,
            deficit_to
          )

        covered_deficit_intervals << clipped if clipped
      end
    end

    covered_minutes =
      merged_interval_minutes(
        covered_deficit_intervals
      )

    deficit_minutes =
      [
        raw_deficit_minutes -
        covered_minutes,
        0
      ].max

    # ------------------------------------------------------------
    # MANUAL ADJUSTMENT
    # ------------------------------------------------------------

    manual_adjust =
      day.manual_adjust_minutes.to_i

    if manual_adjust > 0
      deficit_minutes =
        [
          deficit_minutes -
          manual_adjust,
          0
        ].max

    elsif manual_adjust < 0

      deficit_minutes +=
        manual_adjust.abs
    end

    [
      deficit_minutes,
      base_overtime_minutes
    ]
  end
end