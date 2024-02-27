module ApplicationHelper
	def unread_notification_count
		current_user.notifications.where(is_read: false).count
	end
	def bootstrap_class_for_flash(type)
		case type
		when 'notice' then 'alert-success'
		when 'alert', 'error' then 'alert-danger'
		else 'alert-info'
		end
	end
end
