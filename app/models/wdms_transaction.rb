# app/models/wdms_transaction.rb
class WdmsTransaction < ApplicationRecord
  def action_time
    # "2025-12-20 21:37:11"
    t = raw_payload.is_a?(String) ? JSON.parse(raw_payload) : raw_payload
    # str = t["action_time"] *********
    str = t["upload_time"]

    return if str.blank?

    # اگر تایم‌زون دستگاهت ثابت است (مثلاً تهران):
    Time.use_zone("Asia/Tehran") { Time.zone.parse(str) }
  rescue JSON::ParserError
    nil
  end

  def action_date
    action_time&.to_date
  end
end
