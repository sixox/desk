class KpiListsController < ApplicationController
  before_action :authenticate_user!

  def new
    @year = params[:year].to_i
    @period = params[:period].to_i

    if @year < 0 || ![0, 1, 2, 3, 4].include?(@period)
      flash[:alert] = "Invalid year or period"
      redirect_to root_path
      return
    end

    @kpi_list = current_user.kpi_lists.find_or_initialize_by(year: @year, period: @period)

    (10 - @kpi_list.targets.size).times { @kpi_list.targets.build }
  end

  def create
    @kpi_list = current_user.kpi_lists.new(kpi_list_params)

    # Remove completely blank targets before saving
    @kpi_list.targets = @kpi_list.targets.reject do |target|
      target.description.blank?
    end

    if current_user.is_manager && current_user.admin?
      @kpi_list.department = "IT"
    elsif current_user.is_manager && current_user.procurement?
      @kpi_list.department = "COO"
    elsif current_user.id == 27
      @kpi_list.department = "AI & Investment"
    elsif current_user.id == 10
      @kpi_list.department = "Logestic"
    elsif current_user.id == 17
      @kpi_list.department = "Strategy & Dev"
    elsif current_user.is_manager && current_user.ceo?
      @kpi_list.department = "Board of Directors"
    else
      @kpi_list.department = current_user.role
    end

    if @kpi_list.save
      redirect_to bulk_new_kpi_list_results_path(@kpi_list), notice: "KPI List saved. Now enter results and KPIs."
    else
      (10 - @kpi_list.targets.size).times { @kpi_list.targets.build }
      render :new, status: :unprocessable_entity
    end
  end


  private

  def kpi_list_params
    params.require(:kpi_list).permit(
      :year,
      :period,
      targets_attributes: [:id, :name, :description, :_destroy]
    )
  end
end
