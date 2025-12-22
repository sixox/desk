# app/controllers/overtime_entries_controller.rb
class OvertimeEntriesController < ApplicationController
  before_action :authenticate_user!

  def new
    @overtime_entry = OvertimeEntry.new
  end

  def create
    @overtime_entry = OvertimeEntry.new(overtime_entry_params)
    @overtime_entry.user_id = current_user.id
    # Default confirmed is true (set by model), manager can later revoke if needed
    if @overtime_entry.save
      flash[:notice] = "Overtime request submitted."
      redirect_to member_path(current_user)  # redirect to appropriate page, e.g., overtime list or dashboard
    else
      flash[:alert] = @overtime_entry.errors.full_messages.to_sentence
      render :new
    end
  end
  def toggle_confirm
    oe = OvertimeEntry.find(params[:id])

  # فقط مدیر مستقیم یا خود شخص بتواند (تو می‌تونی سخت‌گیرترش کنی)
  allowed_user_ids = current_user.direct_reports.pluck(:id) | [current_user.id]
  unless allowed_user_ids.include?(oe.user_id)
    return redirect_back fallback_location: root_path, alert: "دسترسی ندارید."
  end

  oe.update!(confirmed: (params[:confirmed].to_s == "1"))

  redirect_back fallback_location: manager_review_salary_archives_path(month_id: params[:month_id]),
  notice: "وضعیت اضافه‌کاری به‌روزرسانی شد."
end


  # (Optional: index or show actions if users need to see their overtime requests)

  private

  def overtime_entry_params
    params.require(:overtime_entry).permit(:date, :hours, :reason, :outside_system)
  end
end
