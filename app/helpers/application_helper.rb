module ApplicationHelper
	def unread_notification_count
    	current_user.notifications.where(is_read: false).count
  	end
end
