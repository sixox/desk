class KpiListsController < ApplicationController
  before_action :authenticate_user!

	def new
	  @year = params[:year].to_i
	  @period = params[:period].to_i

	  # Make sure both year and period are valid before proceeding
	  if @year <= 0 || ![1, 2, 3, 4].include?(@period)
	    flash[:alert] = "Invalid year or period"
	    redirect_to some_path # or render :new again
	  end

	  @kpi_list = current_user.kpi_lists.find_or_initialize_by(year: @year, period: @period)

	  (10 - @kpi_list.targets.size).times { @kpi_list.targets.build }
	end



	def create
	  @kpi_list = current_user.kpi_lists.new(kpi_list_params)

	  if @kpi_list.save
	    # Redirect to the result form for the first target
	    redirect_to new_kpi_list_result_path(@kpi_list, target_id: @kpi_list.targets.first.id), notice: "KPI List saved. Now enter results and KPIs."
	  else
	    # Make sure 10 targets are shown if none are filled
	    (10 - @kpi_list.targets.size).times { @kpi_list.targets.build }
logger.error @kpi_list.errors.full_messages.to_sentence
	  @kpi_list.targets.each { |target| logger.error target.errors.full_messages.to_sentence }
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
