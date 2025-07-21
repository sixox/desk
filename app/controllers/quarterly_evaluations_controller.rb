class QuarterlyEvaluationsController < ApplicationController
  before_action :authenticate_user!

  def new
    @kpi_list = KpiList.find(params[:kpi_list_id])
    @year = params[:year].to_i

    @existing_periods = current_user.quarterly_evaluations
                          .where(kpi_list: @kpi_list, year: @year)
                          .pluck(:period)

    @evaluation = current_user.quarterly_evaluations.build(
      kpi_list: @kpi_list,
      year: @year
    )

    @results = @kpi_list.targets.includes(:results).flat_map(&:results)

    @results.each do |result|
      @evaluation.done_actions.build(result: result)
      @evaluation.undone_actions.build(result: result)
    end

    @past_done_actions = DoneAction
      .includes(:quarterly_evaluation)
      .where(quarterly_evaluations: { user_id: current_user.id, kpi_list_id: @kpi_list.id })
      .where.not(description: [nil, ""])

    @past_undone_actions = UndoneAction
      .includes(:quarterly_evaluation)
      .where(quarterly_evaluations: { user_id: current_user.id, kpi_list_id: @kpi_list.id })
      .where.not(description: [nil, ""])
  end

  def create
    @evaluation = current_user.quarterly_evaluations.build(filtered_evaluation_params)

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

      @results = @kpi_list.targets.includes(:results).flat_map(&:results)

      @past_done_actions = DoneAction
        .joins(:quarterly_evaluation)
        .where(quarterly_evaluations: { user: current_user, kpi_list_id: @kpi_list.id })
        .where.not(quarterly_evaluations: { id: @evaluation.id })

      @past_undone_actions = UndoneAction
        .joins(:quarterly_evaluation)
        .where(quarterly_evaluations: { user: current_user, kpi_list_id: @kpi_list.id })
        .where.not(quarterly_evaluations: { id: @evaluation.id })

      flash.now[:alert] = "There were errors. Please fix and resubmit."
      render :new
    end
  end

  def edit
    @evaluation = QuarterlyEvaluation.find(params[:id])
    @kpi_list = @evaluation.kpi_list
    @year = @evaluation.year

    @existing_periods = current_user.quarterly_evaluations
                          .where(kpi_list: @kpi_list, year: @year)
                          .where.not(id: @evaluation.id)
                          .pluck(:period)

    @results = @kpi_list.targets.includes(:results).flat_map(&:results)

    @past_done_actions = DoneAction
      .includes(:quarterly_evaluation)
      .where(quarterly_evaluations: { user_id: current_user.id, kpi_list_id: @kpi_list.id })
      .where.not(description: [nil, ""])
      .where.not(quarterly_evaluations: { id: @evaluation.id })

    @past_undone_actions = UndoneAction
      .includes(:quarterly_evaluation)
      .where(quarterly_evaluations: { user_id: current_user.id, kpi_list_id: @kpi_list.id })
      .where.not(description: [nil, ""])
      .where.not(quarterly_evaluations: { id: @evaluation.id })
  end


  def update
    @evaluation = QuarterlyEvaluation.find(params[:id])
    if @evaluation.update(filtered_evaluation_params)
      redirect_to member_path(@evaluation.user), notice: "Quarterly evaluation updated successfully."
    else
      @kpi_list = @evaluation.kpi_list
      @results = @kpi_list.targets.includes(:results).flat_map(&:results)

      @past_done_actions = DoneAction
        .includes(:quarterly_evaluation)
        .where(quarterly_evaluations: { user_id: @evaluation.user_id, kpi_list_id: @kpi_list.id })
        .where.not(quarterly_evaluations: { id: @evaluation.id })

      @past_undone_actions = UndoneAction
        .includes(:quarterly_evaluation)
        .where(quarterly_evaluations: { user_id: @evaluation.user_id, kpi_list_id: @kpi_list.id })
        .where.not(quarterly_evaluations: { id: @evaluation.id })

      flash.now[:alert] = "There were errors. Please fix and resubmit."
      render :edit
    end
  end

  def review
    @evaluation = QuarterlyEvaluation.find(params[:id])
    @kpi_list = @evaluation.kpi_list
  end

  def submit_review
    @evaluation = QuarterlyEvaluation.find(params[:id])
    @evaluation.review_mode = true

    if @evaluation.update(review_params)
      redirect_to member_path(current_user), notice: "Review submitted successfully."
    else
      @kpi_list = @evaluation.kpi_list
      flash.now[:alert] = "Please correct the errors below."
      render :review
    end
  end

  private

  def review_params
    params.require(:quarterly_evaluation).permit(
      done_actions_attributes: [:id, :weight, :point],
      undone_actions_attributes: [:id]
    )
  end

  def filtered_evaluation_params
    raw = params.require(:quarterly_evaluation).permit(
      :kpi_list_id,
      :year,
      :period,
      :comment,
      done_actions_attributes: [:id, :description, :result_id],
      undone_actions_attributes: [:id, :description, :result_id],
      files: []
    )

    # Only keep filled-in done actions
    if raw[:done_actions_attributes].is_a?(ActionController::Parameters) || raw[:done_actions_attributes].is_a?(Hash)
      raw[:done_actions_attributes] = raw[:done_actions_attributes].values.select do |attrs|
        attrs[:description].present? || attrs[:id].present?
      end
    end

    # Only keep filled-in undone actions
    if raw[:undone_actions_attributes].is_a?(ActionController::Parameters) || raw[:undone_actions_attributes].is_a?(Hash)
      raw[:undone_actions_attributes] = raw[:undone_actions_attributes].values.select do |attrs|
        attrs[:description].present? || attrs[:id].present?
      end
    end

    raw
  end
end
