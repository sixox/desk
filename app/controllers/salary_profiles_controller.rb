# frozen_string_literal: true

class SalaryProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_accounting_manager!

  def bulk_edit
    @users = User
      .joins(:salary_profile)
      .includes(:salary_profile)
      .by_name
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

  def sanitize_profile_attrs(attrs)
    attrs = attrs.to_h

    # Pay type
    attrs["pay_type"] = attrs["pay_type"].to_s.presence

    # Integers (allow blank => nil)
    int_fields = %w[
      seniority_base
      monthly_seniority_base
      housing_allowance
      food_allowance
      marriage_allowance
      child_allowance
      total_salary
      loan_installment
      fund_three_percent
      fund_six_percent
    ]

    int_fields.each do |k|
      v = attrs[k]
      attrs[k] = v.present? ? v.to_i : nil
    end

    # Decimal
    if attrs["hourly_rate"].present?
      attrs["hourly_rate"] = BigDecimal(attrs["hourly_rate"].to_s)
    else
      attrs["hourly_rate"] = nil
    end

    attrs.slice(
      "pay_type",
      "seniority_base",
      "monthly_seniority_base",
      "housing_allowance",
      "food_allowance",
      "marriage_allowance",
      "child_allowance",
      "total_salary",
      "hourly_rate",
      "loan_installment",
      "fund_three_percent",
      "fund_six_percent"
    )
  end
end
