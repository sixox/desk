class QuarterlyEvaluationsController < ApplicationController
  before_action :authenticate_user!

  def new
    @kpi_list = KpiList.find(params[:kpi_list_id])
    @year = params[:year].to_i

    # Prevent duplicates for this user/KPI/year/period
    @existing_periods = current_user.quarterly_evaluations
                          .where(kpi_list: @kpi_list, year: @year)
                          .pluck(:period)

    @evaluation = current_user.quarterly_evaluations.build(
      kpi_list: @kpi_list,
      year: @year
    )

    15.times { @evaluation.done_actions.build }
    9.times { @evaluation.undone_actions.build }
  end

  def create
    @evaluation = current_user.quarterly_evaluations.build(filtered_evaluation_params)

    # Prevent duplicate
    if QuarterlyEvaluation.exists?(user: current_user, kpi_list_id: @evaluation.kpi_list_id, year: @evaluation.year, period: @evaluation.period)
      redirect_to quarterly_evaluations_path, alert: "You already submitted this evaluation." and return
    end

    if @evaluation.save
      redirect_to member_path(current_user), notice: "Quarterly evaluation submitted successfully."
    else
      @kpi_list = @evaluation.kpi_list
      @year = @evaluation.year
      @existing_periods = current_user.quarterly_evaluations
                            .where(kpi_list: @kpi_list, year: @year)
                            .pluck(:period)
      flash.now[:alert] = "There were errors. Please fix and resubmit."
      render :new
    end
  end

  private

  def filtered_evaluation_params
    raw = params.require(:quarterly_evaluation).permit(
      :kpi_list_id,
      :year,
      :period,
      :comment,
      done_actions_attributes: [:description],
      undone_actions_attributes: [:description],
      files: []
    )

    # Filter out blank done actions
    if raw[:done_actions_attributes].is_a?(ActionController::Parameters)
      raw[:done_actions_attributes] = raw[:done_actions_attributes].values.reject { |attrs| attrs[:description].blank? }
    end

    # Filter out blank undone actions
    if raw[:undone_actions_attributes].is_a?(ActionController::Parameters)
      raw[:undone_actions_attributes] = raw[:undone_actions_attributes].values.reject { |attrs| attrs[:description].blank? }
    end

    raw
  end
end
