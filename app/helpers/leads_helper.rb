# app/helpers/leads_helper.rb
module LeadsHelper
  def human_duration(seconds)
    return "—" unless seconds
    secs = seconds.to_i
    parts = []
    [[86_400, "d"], [3_600, "h"], [60, "m"]].each do |unit, label|
      v = secs / unit
      if v > 0
        parts << "#{v}#{label}"
        secs -= v * unit
      end
    end
    parts << "#{secs}s" if parts.empty?
    parts.join(" ")
  end

  def lead_status_label(key)
    key.to_s.humanize
  end

  def status_header_badge_class(status_key)
    {
      "new_lead"   => "secondary",
      "contacted"  => "info",
      "responded"  => "primary",
      "offer_sent" => "warning",
      "negotiation"=> "dark",
      "won"        => "success",
      "lost"       => "danger"
    }[status_key] || "secondary"
  end

  def status_badge(lead)
    content_tag :span, lead.status.humanize, class: "badge bg-#{lead.badge_class}"
  end
end
