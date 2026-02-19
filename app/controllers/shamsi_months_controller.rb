# app/controllers/shamsi_months_controller.rb
class ShamsiMonthsController < ApplicationController
  def new
    @shamsi_month = ShamsiMonth.new
  end

  def create
    @shamsi_month = ShamsiMonth.new(shamsi_month_params)
    if @shamsi_month.save
      redirect_to salary_admin_path, notice: "ماه با موفقیت ساخته شد."
    else
      render :new
    end
  end

  def edit_day_offs
    @shamsi_month = ShamsiMonth.find(params[:id])
    @date_range = (@shamsi_month.start_at.to_date..@shamsi_month.end_at.to_date).to_a

    # existing (day off)
    @selected_offs = @shamsi_month.day_offs.pluck(:day)

    # NEW (month-level remote days)
    @selected_remote_days = @shamsi_month.shamsi_month_remote_days.pluck(:day)
  end

  def update_day_offs
    @shamsi_month = ShamsiMonth.find(params[:id])

    # existing (day off)
    selected_offs = params[:off_days]&.map(&:to_date) || []
    @shamsi_month.day_offs.where.not(day: selected_offs).destroy_all
    selected_offs.each { |day| DayOff.find_or_create_by(shamsi_month: @shamsi_month, day: day) }

    # NEW (month-level remote days)
    selected_remote = params[:remote_days]&.map(&:to_date) || []
    @shamsi_month.shamsi_month_remote_days.where.not(day: selected_remote).destroy_all
    selected_remote.each do |day|
      ShamsiMonthRemoteDay.find_or_create_by(shamsi_month: @shamsi_month, day: day)
    end

    redirect_to salary_admin_path, notice: "روزهای تعطیل و دورکاری ماه ذخیره شد."
  end

  private

  def shamsi_month_params
    params.require(:shamsi_month).permit(:name, :start_at, :end_at, :total_days)
  end
end
