class AssessmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_filler, only: %i[index form update_form]
  
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

  def update_form
    all_updated = true

    # Iterate through each submitted assessment form parameter
    assessment_forms_params.each do |id, form_params|
      assessment_form = AssessmentForm.find(id)
      unless assessment_form.update(form_params)
        all_updated = false # Set the flag to false if any update fails
      end
    end

    if all_updated
      redirect_to assessments_path, notice: 'All assessment forms were successfully updated.'
    else
      # If any update failed, render the form again with errors
      @user = User.find(params[:user_id]) # Retrieve the user again
      @assessment_forms = AssessmentForm.by_user_and_filler(@user, @filler)
      render :form # Render the form view to show errors
    end
  end

  private

  def set_filler
    @filler = current_user
  end

  def assessment_params
    params.require(:assessment).permit(:category, :category_point, :criterion, :definition, :title)
  end

  def assessment_forms_params
    # Use the nested structure correctly to allow for multiple forms
    params.require(:assessment_forms).permit(
      # Permit fields for each assessment form
      :total_score,
      :weight,
      :score,
      :assessment_id,
      :user_id,
      :filler_id
    ).to_h # Convert to hash if necessary
  end
end
