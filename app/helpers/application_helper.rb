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

	def risk_level_tag(project)
		if project.risk.present?
			case project.risk
			when 1..15
				content_tag(:span, "Low Risk", class: 'risk-low')
			when 16..25
				content_tag(:span, "Medium Risk", class: 'risk-medium')
			when 26..36
				content_tag(:span, "High Risk", class: 'risk-high')
			when 37..Float::INFINITY
				content_tag(:span, "Extreme Risk", class: 'risk-extreme')
			else
				content_tag(:span, "No Risk Data", class: 'no-risk')
			end
		else
			content_tag(:span, "No Risk Data", class: 'text-secondary')
		end


	end
end
