class ApplicationController < ActionController::Base
  include AmountConverter


  helper_method :count_not_confirmed_vacations
  helper_method :unread_messages_count

  # This should be inside a specific controller action
  # before_action :set_notifications


  private

  def unread_messages_count
    unread_from_observers = MessageObserver.joins(:message)
      .where(observer: current_user, read: false)
      .distinct
      .count(:message_id)

    unread_from_statuses = MessageStatus.where(user: current_user, status: 'unread').count

    unread_from_observers + unread_from_statuses
  end

  def count_not_confirmed_vacations
    @count_not_confirmed_vacations ||= Vacation.joins(:user).where(users: { role: current_user.role }, confirm: [nil, false]).count
  end

  # def set_notifications
  # 	return if !user_signed_in?
  #   @notifications = current_user.notifications.where(is_read: false).last(8).reverse
  # end
end
