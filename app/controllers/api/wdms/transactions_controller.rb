# frozen_string_literal: true
require "digest"
require "time"

class Api::Wdms::TransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def bulk_create
    expected = ENV.fetch("WDMS_SYNC_TOKEN", "").to_s

    # Rack معمولاً هدرها را اینطوری می‌گذارد:
    token = request.get_header("HTTP_X_WDMS_TOKEN").to_s
    token = request.headers["X-WDMS-TOKEN"].to_s if token.blank?
    token = token.strip

    unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
      Rails.logger.warn("WDMS auth failed: token='#{token}' expected='#{expected}'")
      return render json: { error: "unauthorized" }, status: :unauthorized
    end

    rows = params.require(:transactions)
    inserted = 0
    max_by_device = {}

    rows.each do |r|
      device_serial = r["device_serial"].to_s.strip
      emp_code      = r["emp_code"].to_s.strip
      # action_time_s = r["action_time"].to_s.strip ***************
      action_time_s = r["upload_time"].to_s.strip


      next if device_serial.empty? || emp_code.empty? || action_time_s.empty?

      occurred_at = parse_action_time_keep_timezone(action_time_s)
      next unless occurred_at

      # مهم: برای جلوگیری از دوباره‌کاری، hash را با همان لحظه‌ی parse‌شده می‌سازیم
      row_hash = Digest::SHA256.hexdigest("#{device_serial}|#{emp_code}|#{occurred_at.iso8601}")

      begin
        WdmsTransaction.create!(
          device_serial: device_serial,
          emp_code: emp_code,
          occurred_at: occurred_at,
          row_hash: row_hash,
          raw_payload: r.to_json
        )
        inserted += 1
      rescue ActiveRecord::RecordNotUnique
        # duplicate -> ignore
      end

      max_by_device[device_serial] = [max_by_device[device_serial], occurred_at].compact.max
    end

    max_by_device.each do |sn, last_time|
      state = WdmsSyncState.find_or_initialize_by(device_serial: sn)
      state.last_occurred_at = [state.last_occurred_at, last_time].compact.max
      state.save!
    end

    render json: { ok: true, inserted: inserted }, status: :ok
  end

  private

  # هیچ تبدیل timezone انجام نمی‌دهد:
  # - اگر ورودی ISO8601 با offset باشد، همان offset را نگه می‌دارد.
  # - اگر ورودی بدون offset باشد، همان ساعت را parse می‌کند (timezone مشخص نیست).
  def parse_action_time_keep_timezone(s)
    str = s.strip

    # حالت بهتر: "2025-12-16T10:40:00+08:00" یا "2025-12-16T10:40:00+08"
    if str.include?("T") && (str.match?(/[+-]\d{2}(:?\d{2})?\z/) || str.end_with?("Z"))
      return Time.iso8601(str)
    end

    # حالت WDMS فعلی شما: "YYYY-MM-DD HH:MM:SS"
    Time.strptime(str, "%Y-%m-%d %H:%M:%S")
  rescue ArgumentError
    nil
  end
end
