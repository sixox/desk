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
    @selected_offs = @shamsi_month.day_offs.pluck(:day) # ← اصلاح از date به day
  end

  def update_day_offs
    @shamsi_month = ShamsiMonth.find(params[:id])
    selected = params[:off_days]&.map(&:to_date) || []

    @shamsi_month.day_offs.destroy_all
    selected.each do |d|
      @shamsi_month.day_offs.create!(day: d) # ← اصلاح از date به day
    end

    redirect_to salary_admin_path, notice: "روزهای تعطیل ذخیره شد"
  end

  private

  def shamsi_month_params
    params.require(:shamsi_month).permit(:name, :start_at, :end_at, :total_days)
  end
end
