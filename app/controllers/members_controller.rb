class MembersController < ApplicationController
	before_action :authenticate_user!, only: %i[show edit_description update_description edit_personal_details update_personal_details]

	def show
		@user = User.find(params[:id])
		@vacations_for_same_role = Vacation.joins(:user)
		.where(users: { role: @user.role })
		.where.not(users: { id: @user.id })
		@vacations = Vacation.all
		@fillers_grouped = fillers_grouped_by_year_and_period(@user)

		@kpi_lists = if @user.procurement? && @user.is_manager?
			KpiList.where(department: "COO")
		elsif @user.admin?
			KpiList.where(department: "IT")
		elsif [10, 16, 31].include?(@user.id)
			KpiList.where(department: "logestic")
		elsif @user.ceo?
			KpiList.where(department: "Board of Directors") 
		elsif @user.id == 17
			KpiList.where(department: "Strategy & Dev")
		elsif @user.id == 27
			KpiList.where(department: "AI & Investment")
		else
			KpiList.where(department: @user.role)
		end


					      # ----------------------------
    # ✅ Paylips + last month hours
    # ----------------------------

    # All archives for this user (newest month first)
    @user_archives = SalaryArchive
    .includes(:shamsi_month, :days)
    .where(user_id: @user.id)
    .references(:shamsi_month)
    .order("shamsi_months.start_at DESC")

    @months = @user_archives.map(&:shamsi_month).compact.uniq

    # Latest archive/month for "hours table"
    @latest_archive = @user_archives.first
    @latest_month   = @latest_archive&.shamsi_month

    # Month selector for paylips (user chooses)
    @selected_month =
    if params[:month_id].present?
    	@months.find { |m| m.id == params[:month_id].to_i }
    else
    	@latest_month
    end

    @selected_archive =
    if @selected_month.present?
    	@user_archives.find { |a| a.shamsi_month_id == @selected_month.id }
    end

    @selected_accounting_confirmed =
    @selected_archive.present? &&
    (@selected_archive.accounting_confirmed_at.present? || @selected_archive.accounting_confirmed == true)

    # Build "manager-like" maps ONLY for latest month (hours status table)
    # If you prefer: build these maps for @selected_month instead; but you asked:
    # "show manager view table for last shamsi month"
    if @latest_month.present? && @latest_archive.present?
    	build_month_context_for_user!(@user.id, @latest_month)
    end




end

def edit_description

end
def update_description
	respond_to do |format|
		if current_user.update(about: params[:user][:about])
			format.turbo_stream { render turbo_stream: turbo_stream.replace('member-description', partial: 'members/member_description', locals: { user: current_user }) }
		end
	end
end

def edit_personal_details
end
def update_personal_details
	respond_to do |format|
		if current_user.update(user_personal_info_params)
			format.turbo_stream { render turbo_stream: turbo_stream.replace('member-personal-details', partial: 'members/member_personal_details', locals: { user: current_user }) }
		end
	end
end

def signatures
	@users = User.all
end

def update_signatures
	@users = User.all
	signatures_params.each do |user_id, signature|
		user = User.find(user_id)
		user.signature.attach(signature) if signature
	end

	redirect_to root_path, notice: "Signatures updated successfully."
end



private

def user_personal_info_params
	params.require(:user).permit(:first_name, :last_name)
end

def signatures_params
	params.require(:signatures).permit!
end

def fillers_grouped_by_year_and_period(user)
	  # Fetch all unique year, period combinations and their fillers
	  user.assessment_forms_as_user
	  .select(:year, :period, :filler_id)
	  .includes(:filler)
	  .distinct
	  .group_by { |form| [form.year, form.period] }
	end


	  # ------------------------------------------------------------
  # ✅ Same data-prep logic as SalaryArchivesController#manager_review
  # but for ONE user + ONE month (used in profile hours table)
  # ------------------------------------------------------------
  def build_month_context_for_user!(user_id, shamsi_month)
    user_ids = [user_id]

    @profile_month = shamsi_month
    @profile_archive = SalaryArchive.includes(:days).find_by(user_id: user_id, shamsi_month_id: shamsi_month.id)

    # These mirror manager_review:
    remote_days = RemoteDay.where(
      user_id: user_ids,
      date: shamsi_month.start_at.to_date..shamsi_month.end_at.to_date
    )
    @remote_days_by_user_date =
      remote_days.group_by(&:user_id).transform_values { |rows| rows.index_by(&:date) }

    overtime_entries = OvertimeEntry.where(
      user_id: user_ids,
      date: shamsi_month.start_at.to_date..shamsi_month.end_at.to_date
    )
    @overtime_by_user_date =
      overtime_entries.group_by(&:user_id).transform_values { |rows| rows.group_by(&:date) }

    manual_entries = ManualEntry.where(
      user_id: user_ids,
      occurred_at: shamsi_month.start_at.beginning_of_day..shamsi_month.end_at.end_of_day
    )
    @manual_by_user_date = build_manual_map(manual_entries)

    @off_dates = shamsi_month.off_dates.to_set
    @weekday_fa = %w[یکشنبه دوشنبه سه‌شنبه چهارشنبه پنجشنبه جمعه شنبه]

    # same vacation map logic (with "preconfirmed" semantics you already added)
    @vacation_info_by_user_date = build_vacation_info_map(user_ids, shamsi_month)

    @fmt_hours = lambda do |minutes|
      m = minutes.to_i
      return 0 if m <= 0
      q = (m / 15.0).round
      (q * 0.25)
    end
  end

  # ---------- helpers copied/adapted from SalaryArchivesController ----------

  def build_vacation_info_map(user_ids, shamsi_month)
    start_t = shamsi_month.start_at.beginning_of_day
    end_t   = shamsi_month.end_at.end_of_day

    vacations = Vacation
      .where(user_id: user_ids)
      .where("start_at <= ? AND end_at >= ?", end_t, start_t)
      .select(:id, :user_id, :hourly, :start_at, :end_at, :confirm, :details, :comment)

    map = Hash.new { |h, k| h[k] = {} }

    vacations.each do |v|
      # ✅ default: preconfirmed (nil => true). Only explicit false is unconfirmed.
      confirmed = (v.confirm != false)

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


end	