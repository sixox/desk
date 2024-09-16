class ApplicationController < ActionController::Base
  include AmountConverter


  helper_method :count_not_confirmed_vacations

  # This should be inside a specific controller action
  before_action :set_notifications

  def count_not_confirmed_vacations
    @count_not_confirmed_vacations ||= Vacation.joins(:user).where(users: { role: current_user.role }, confirm: [nil, false]).count
  end

  def set_notifications
  	return if !user_signed_in?
    @notifications = current_user.notifications.where(is_read: false).last(8).reverse
  end
end
