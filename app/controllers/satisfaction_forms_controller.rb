class SatisfactionFormsController < ApplicationController
  before_action :authenticate_user!

  # Display all SatisfactionForms for the current user
  def index
    @satisfaction_forms = current_user.satisfaction_forms.includes(:satisfaction)
  end

  # Update all SatisfactionForm records with submitted answers
  def update_all
    all_updated = true

    satisfaction_form_params.each do |id, form_params|
      satisfaction_form = SatisfactionForm.find(id)
      unless satisfaction_form.update(form_params)
        all_updated = false
      end
    end

    if all_updated
      redirect_to satisfaction_forms_path, notice: 'All forms were successfully updated.'
    else
      @satisfaction_forms = current_user.satisfaction_forms.includes(:satisfaction)
      flash.now[:alert] = 'Some forms could not be updated. Please check for errors.'
      render :index
    end
  end

  private

  def satisfaction_form_params
    params.require(:satisfaction_forms).permit!
  end
end
