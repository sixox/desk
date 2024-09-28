class AssessmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_filler, only: %i[index form update]
  
  def index
    @unique_users = AssessmentForm.unique_users_for_filler(@filler)
  end

  def show
    @assessment = Assessment.find(params[:id])
  end

  def new
    @assessment = Assessment.new
  end

  def create
    @assessment = Assessment.new(assessment_params)
    if @assessment.save
      redirect_to assessments_path, notice: 'Assessment was successfully created.'
    else
      render :new
    end
  end

  def form
    @user = User.find(params[:user_id])
    @assessment_forms = AssessmentForm.by_user_and_filler(@user, @filler)
  end

  def update
    # Loop through each assessment form ID and update it
    assessment_forms_params.each do |id, form_params|
      assessment_form = AssessmentForm.find(id)
      assessment_form.update(form_params)
    end

    redirect_to assessments_path, notice: 'All assessment forms were successfully updated.'
  end

  private

  def set_filler
    @filler = current_user
  end

  def assessment_params
    params.require(:assessment).permit(:category, :category_point, :criterion, :definition, :title)
  end

  def assessment_forms_params
    params.require(:assessment_forms).permit(
      :total_score, 
      :weight, 
      :score, 
      :assessment_id, 
      :user_id, 
      :filler_id
    )
  end
end
