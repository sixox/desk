# app/controllers/candidate_evaluations_controller.rb
class CandidateEvaluationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_candidate
  before_action :set_department!
  before_action :authorize_department_access!
  before_action :set_evaluation, only: %i[show edit update]

  def new
    @candidate_evaluation =
      @candidate.candidate_evaluations.find_or_initialize_by(department: @department)
    @candidate_evaluation.user ||= current_user
    @candidate_evaluation.prepare_questions!
  end

  def create
    @candidate_evaluation =
      @candidate.candidate_evaluations.find_or_initialize_by(department: @department)
    @candidate_evaluation.user ||= current_user
    @candidate_evaluation.assign_attributes(evaluation_params)
    @candidate_evaluation.prepare_questions!

    if @candidate_evaluation.save
      redirect_to candidate_candidate_evaluation_path(@candidate, department: @department),
                  notice: "فرم #{@department} ثبت شد."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @candidate_evaluation.prepare_questions!
  end

  def update
    @candidate_evaluation.assign_attributes(evaluation_params)
    @candidate_evaluation.prepare_questions!
    if @candidate_evaluation.save
      redirect_to candidate_candidate_evaluation_path(@candidate, department: @department),
                  notice: "فرم #{@department} به‌روزرسانی شد."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_candidate
    @candidate = Candidate.find(params[:candidate_id])
  end

  def set_department!
    @department = params[:department].presence || "HR"
    unless CandidateEvaluation::DEPARTMENTS.include?(@department)
      redirect_to candidates_path, alert: "دپارتمان نامعتبر" and return
    end
  end

  def authorize_department_access!
    case @department
    when "HR"
      head :forbidden unless current_user.role == "hr" || current_user.role == "admin"
    when "CEO"
      head :forbidden unless current_user.role == "ceo" || current_user.role == "admin" ||
                            (current_user.is_manager && current_user.role == "procurement")
    when "Accounting"
      head :forbidden unless current_user.role == "accounting" || current_user.role == "admin"
      if @candidate.role != "accounting"
        redirect_to candidates_path, alert: "این فرم فقط برای کاندیدای حسابداری است." and return
      end
    when "Other"
      if @candidate.role == "accounting"
        redirect_to candidates_path, alert: "این فرم برای کاندیدای غیرحسابداری است." and return
      end
      head :forbidden unless %w[hr ceo admin].include?(current_user.role) ||
                            (current_user.is_manager && current_user.role == @candidate.role)
    end
  end

  def set_evaluation
    @candidate_evaluation =
      @candidate.candidate_evaluations.find_by(department: @department)
    redirect_to new_candidate_candidate_evaluation_path(@candidate, department: @department) unless @candidate_evaluation
  end

  def evaluation_params
    params.require(:candidate_evaluation).permit(
      :comment, :overall_grade,
      questions_attributes: [:id, :position, :text, :weight, :score]
    )
  end
end
