class ApplicationController < ActionController::Base
  # This should be inside a specific controller action
  before_action :set_notifications

  def set_notifications
  	return if !user_signed_in?
    @notifications = current_user.notifications.where(is_read: false).last(8).reverse
  end
end
