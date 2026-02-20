# app/controllers/salary_profiles_controller.rb
# frozen_string_literal: true

class SalaryProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_accounting_manager!

  def bulk_edit
    @users = User
      .joins(:salary_profile)
      .includes(:salary_profile)
      .order("users.id ASC")
  end

  def bulk_update
    profiles_params = params[:salary_profiles] || {}

    SalaryProfile.transaction do
      profiles_params.each do |profile_id, attrs|
        sp = SalaryProfile.find_by(id: profile_id)
        next unless sp

        sp.update!(sanitize_profile_attrs(attrs))
      end
    end

    redirect_to bulk_edit_salary_profiles_path, notice: "ذخیره شد."
  end

  private

  def authorize_accounting_manager!
    head :forbidden unless ((current_user.accounting? && current_user.is_manager) || current_user.admin?)
  end

  # ✅ FIX: permit first, then to_h
  def sanitize_profile_attrs(attrs)
    attrs = attrs.is_a?(ActionController::Parameters) ? attrs.permit(
      :pay_type,
      :total_salary,
      :hourly_rate,
      :seniority_base,
      :monthly_seniority_base,
      :housing_allowance,
      :food_allowance,
      :marriage_allowance,
      :child_allowance,
      :loan_installment,
      :fund_three_percent,
      :fund_six_percent
    ).to_h : attrs.to_h

    # normalize pay_type
    attrs["pay_type"] = attrs["pay_type"].to_s.presence

    # cast numeric values (nil/"" => 0)
    int_fields = %w[
      total_salary seniority_base monthly_seniority_base housing_allowance food_allowance
      marriage_allowance child_allowance loan_installment fund_three_percent fund_six_percent
    ]
    int_fields.each { |k| attrs[k] = attrs[k].to_i }

    # hourly_rate can be decimal
    attrs["hourly_rate"] = attrs["hourly_rate"].to_s.strip
    attrs["hourly_rate"] = attrs["hourly_rate"].present? ? BigDecimal(attrs["hourly_rate"]) : BigDecimal("0")

    attrs
  end
end