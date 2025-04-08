class ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_kpi_list

  def new
    @target = @kpi_list.targets.find(params[:target_id])
    @result = @target.results.build
  end

	def create
	  @target = @kpi_list.targets.find(params[:target_id])
	  @result = @target.results.build(result_params)

	  if @result.save
	    next_target = @kpi_list.targets.where("id > ?", @target.id).first
	    if next_target
	      redirect_to new_kpi_list_result_path(@kpi_list, target_id: next_target.id), notice: "Result saved. Continue entering results."
	    else
	      redirect_to kpi_list_path(@kpi_list), notice: "All results saved. KPI process complete."
	    end
	  else
	    render :new, status: :unprocessable_entity
	  end
	end


  private

  def set_kpi_list
    @kpi_list = current_user.kpi_lists.find(params[:kpi_list_id])
  end

  def result_params
    params.require(:result).permit(:description, :kpi_value, :unit)
  end
end
