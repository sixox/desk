# app/controllers/salary_admin_controller.rb
class SalaryAdminController < ApplicationController
  def index
    @latest_month = ShamsiMonth.order(start_at: :desc).first
  end
end
