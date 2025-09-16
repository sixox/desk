class SatisfactionFormsController < ApplicationController
  before_action :authenticate_user!

  # Display all SatisfactionForms for the current user
  def index
    @grouped_forms = current_user.satisfaction_forms.includes(:satisfaction)
    .group_by { |sf| [sf.year, sf.period] }

    current_year = 1404
    current_period = 1

    @new_forms = current_user.satisfaction_forms
    .where(year: current_year, period: current_period, answer: nil)
    .includes(:satisfaction)
  end


def result
  @grouped_satisfactions = {}

  Satisfaction.includes(satisfaction_forms: :user).find_each do |satisfaction|
    satisfaction.satisfaction_forms.group_by { |f| [f.year, f.period] }.each do |(year, period), forms|
      @grouped_satisfactions[[year, period]] ||= []
      # Clone the satisfaction and attach only forms from that year+period
      new_satisfaction = satisfaction.dup
      new_satisfaction.define_singleton_method(:satisfaction_forms) { forms }
      @grouped_satisfactions[[year, period]] << new_satisfaction
    end
  end

  @users_per_group = {}

  User.includes(:satisfaction_forms).find_each do |u|
    u.satisfaction_forms.group_by { |f| [f.year, f.period] }.each do |(year, period), forms|
      if forms.all? { |f| f.answer.present? }
        @users_per_group[[year, period]] ||= []
        @users_per_group[[year, period]] << u
      end
    end
  end
end


  def update_all
    all_updated = true

    satisfaction_form_params.each do |id, form_params|
      satisfaction_form = SatisfactionForm.find(id)
      unless satisfaction_form.update(form_params)
        all_updated = false
      end
    end

    if all_updated
      redirect_to satisfaction_forms_path, notice: 'Your form was successfully sent.'
    else
      current_year = 1404
      current_period = 1

      @new_forms = current_user.satisfaction_forms
      .where(year: current_year, period: current_period)
      .includes(:satisfaction)
      flash.now[:alert] = 'Some forms could not be updated. Please check for errors.'
      render :index
    end
  end



  private

  def satisfaction_form_params
    params.require(:satisfaction_forms).permit!
  end
end
