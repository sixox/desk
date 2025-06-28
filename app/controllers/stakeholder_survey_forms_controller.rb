class StakeholderSurveyFormsController < ApplicationController
  before_action :authenticate_user!

	def index
	  @current_year = 1403
	  @current_period = 3

	  # Forms grouped by [year, period], only those that have answers
	  @grouped_forms = StakeholderSurveyForm
	    .includes(:user, :stakeholder_survey)
	    .group_by { |f| [f.year, f.period] }

	  # Check if current user has completed the current period
	  @current_user_forms = current_user.stakeholder_survey_forms
	    .where(year: @current_year, period: @current_period)

	  @should_fill_form = @current_user_forms.empty? || @current_user_forms.any? { |f| f.answer.nil? }
	end

	def new
	  @current_year = 1403
	  @current_period = 3

	  @new_forms = current_user.stakeholder_survey_forms
	    .includes(:stakeholder_survey)
	    .where(year: @current_year, period: @current_period)
	    .order('stakeholder_surveys.position')
	    .joins(:stakeholder_survey)
	end

  def update_all
    all_updated = true

    stakeholder_survey_form_params.each do |id, form_params|
      form = StakeholderSurveyForm.find(id)
      unless form.update(form_params)
        all_updated = false
      end
    end

    if all_updated
      redirect_to stakeholder_survey_forms_path, notice: 'Your responses were submitted.'
    else
      current_year = 1403
      current_period = 3

      @grouped_forms = current_user.stakeholder_survey_forms
                                   .includes(:stakeholder_survey)
                                   .where.not(answer: nil)
                                   .group_by { |sf| [sf.year, sf.period] }

      @new_forms = current_user.stakeholder_survey_forms
                               .includes(:stakeholder_survey)
                               .where(year: current_year, period: current_period)
                               .order('stakeholder_surveys.position')
                               .joins(:stakeholder_survey)

      flash.now[:alert] = "Some responses were invalid. Please fix them and submit again."
      render :index
    end
  end

  private

  def stakeholder_survey_form_params
    params.require(:stakeholder_survey_forms).permit!
  end
end
