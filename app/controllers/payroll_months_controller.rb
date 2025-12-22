class PayrollMonthsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_month, only: %i[show edit update]

  def index
    @months = PayrollMonth.order(start_on: :desc)
  end

  def new
    @month = PayrollMonth.new
  end

  def create
    @month = PayrollMonth.new(month_params)

    if @month.save
      redirect_to edit_payroll_month_path(@month), notice: "Payroll month created. Please mark holidays."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
    @days = @month.payroll_days.order(:day_on)
  end

  def update
    if @month.update(update_params)
      redirect_to edit_payroll_month_path(@month), notice: "Saved."
    else
      @days = @month.payroll_days.order(:day_on)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_month
    @month = PayrollMonth.find(params[:id])
  end

  def month_params
    params.require(:payroll_month).permit(:title, :start_on, :end_on, :days_count)
  end

  def update_params
    params.require(:payroll_month).permit(
      payroll_days_attributes: [:id, :holiday, :note]
    )
  end
end
