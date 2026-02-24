# app/controllers/salary_admin_controller.rb
class SalaryAdminController < ApplicationController
  before_action :authenticate_user!

# app/controllers/salary_admin_controller.rb
def index
  @months = ShamsiMonth.order(id: :desc)

  # قبلا احتمالا این بود:
  # @latest_month = @months.first
  #
  # ✅ حالا: اگر month_id تو params بود، همونو فعال کن؛ وگرنه آخرین ماه
  @latest_month =
  if params[:month_id].present?
    ShamsiMonth.find_by(id: params[:month_id]) || @months.first
  else
    @months.first
  end
end
end