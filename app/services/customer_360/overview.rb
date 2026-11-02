
# app/services/customer_360/overview.rb

module Customer360
  class Overview
    CURRENCIES = Pi::CURRENCY.map(&:to_s).freeze

    DEFAULT_MONTHS = 12

    BOOKING_DATE_FIELDS = {
      factory_order_date: "Factory order",
      pick_up_date: "Cargo picked up",
      custom_submission_date: "Customs documents submitted",
      vessel_eta: "Vessel ETA"
    }.freeze

    attr_reader :customer, :pis, :projects, :cis, :swifts, :bookings, :as_of

    def initialize(customer, as_of: Date.current, months: DEFAULT_MONTHS)
      @customer = customer
      @as_of = as_of.to_date
      @months = months.to_i.clamp(1, 36)

      load_records
    end

    # ==========================================================
    # RECORD COLLECTION
    # ==========================================================

    
    def load_records
      @pis = customer.pis
      .includes(
        :project,
        cis: [:swift, :project]
        )
      .order(issue_date: :asc, created_at: :asc)
      .to_a

      @pi_by_id = pis.index_by(&:id)

      @pis_by_project_id = pis
      .select { |pi| pi.project_id.present? }
      .group_by(&:project_id)

      @cis = pis
      .flat_map { |pi| pi.cis.to_a }
      .uniq(&:id)

  # Include projects connected through either a PI or a CI.
  @projects = (
    pis.filter_map(&:project) +
    cis.filter_map(&:project)
    ).uniq(&:id)
  .sort_by { |project| project.created_at || Time.at(0) }
  .reverse

  @cis_by_project_id = cis
  .select { |ci| ci.project_id.present? }
  .group_by(&:project_id)

  @ci_ids = cis.map(&:id)
  @project_ids = projects.map(&:id)

  swift_conditions = []

  swift_conditions << Swift.where(project_id: @project_ids) if @project_ids.any?
  swift_conditions << Swift.where(ci_id: @ci_ids) if @ci_ids.any?

  swift_relation =
  if swift_conditions.empty?
    Swift.none
  else
    swift_conditions.reduce { |left, right| left.or(right) }
  end

  @swifts = swift_relation
  .includes(:bank, :ci, :project)
  .distinct
  .order(created_at: :desc)
  .to_a

  @bookings = projects
  .flat_map { |project| project.bookings.to_a }
  .uniq(&:id)

  @bookings_by_project_id = bookings.group_by(&:project_id)
end


    # ==========================================================
    # BASIC SUMMARY
    # ==========================================================

    def summary
      {
        pi_count: pis.size,
        projects_count: projects.size,
        pis_without_project_count: pis.count { |pi| pi.project_id.blank? },
        ci_count: cis.size,
        swift_count: swifts.size,
        booking_count: bookings.size,

        container_quantity: bookings.sum { |booking| decimal(booking.quantity) },
        containers_filled: bookings.sum { |booking| decimal(booking.filled) },
        containers_picked_up: bookings.sum { |booking| decimal(booking.picked_up) },

        ci_net_weight: cis.sum { |ci| decimal(ci.net_weight) },
        ci_gross_weight: cis.sum { |ci| decimal(ci.gross_weight) },

        sales_completed_count: projects.count(&:sales_done?),
        logistics_completed_count: projects.count(&:logistics_done?),

        projects_in_progress_count: projects.count do |project|
          !project.sales_done? && !project.logistics_done?
        end
      }
    end

    # ==========================================================
    # INVOICE VALUES
    # CI.balance_payment IS THE INVOICE VALUE
    # ==========================================================

    def invoice_amounts(sent: nil)
      key = case sent
      when true then :sent
      when false then :unsent
      else :all
      end

      @invoice_amounts ||= {}

      @invoice_amounts[key] ||= begin
        selected_cis = case sent
        when true
         cis.select { |ci| ci.sent == true }
       when false
         cis.reject { |ci| ci.sent == true }
       else
         cis
       end

       sum_by_currency(selected_cis) do |ci|
        [
          pi_currency(ci),
          ci.balance_payment
        ]
      end
    end
  end

    # ==========================================================
    # RECEIPT STATUS
    # ==========================================================

    def confirmed_swifts
      @confirmed_swifts ||= swifts.select do |swift|
        swift.confirmed == true && swift.rejected != true
      end
    end

    def pending_swifts
      @pending_swifts ||= swifts.select do |swift|
        swift.confirmed != true && swift.rejected != true
      end
    end

    def rejected_swifts
      @rejected_swifts ||= swifts.select do |swift|
        swift.rejected == true && swift.confirmed != true
      end
    end

    def conflicting_swifts
      @conflicting_swifts ||= swifts.select do |swift|
        swift.confirmed == true && swift.rejected == true
      end
    end

    def receipt_status_counts
      {
        confirmed: confirmed_swifts.size,
        pending: pending_swifts.size,
        rejected: rejected_swifts.size,
        conflicting: conflicting_swifts.size
      }
    end

    # ==========================================================
    # CUSTOMER RECEIPTS
    # Swift.amount IS CUSTOMER-SENT AMOUNT
    # ==========================================================

    def confirmed_receipt_amounts
      @confirmed_receipt_amounts ||= swift_amounts(
        confirmed_swifts,
        :amount,
        ->(swift) { swift.currency }
        )
    end

    def advance_receipts
      @advance_receipts ||= confirmed_swifts.select do |swift|
        swift.advance == true
      end
    end

    def balance_receipts
      @balance_receipts ||= confirmed_swifts.reject do |swift|
        swift.advance == true
      end
    end

    def confirmed_advance_amounts
      @confirmed_advance_amounts ||= swift_amounts(
        advance_receipts,
        :amount,
        ->(swift) { swift.currency }
        )
    end

    def confirmed_balance_amounts
      @confirmed_balance_amounts ||= swift_amounts(
        balance_receipts,
        :amount,
        ->(swift) { swift.currency }
        )
    end

    def pending_receipt_amounts
      @pending_receipt_amounts ||= swift_amounts(
        pending_swifts,
        :amount,
        ->(swift) { swift.currency }
        )
    end

    def rejected_receipt_amounts
      @rejected_receipt_amounts ||= swift_amounts(
        rejected_swifts,
        :amount,
        ->(swift) { swift.currency }
        )
    end

    # ==========================================================
    # BANK RECONCILIATION
    #
    # deposited_amount belongs to the receiving Bank currency.
    # ==========================================================

    def bank_credited_amounts
      @bank_credited_amounts ||= swift_amounts(
        confirmed_swifts,
        :deposited_amount,
        ->(swift) { swift.bank&.currency }
        )
    end

    def missing_bank_amount_swifts
      confirmed_swifts.select do |swift|
        swift.deposited_amount.nil?
      end
    end

    def cross_currency_bank_swifts
      confirmed_swifts.select do |swift|
        swift.bank&.currency.present? &&
          normalize_currency(swift.currency) != normalize_currency(swift.bank.currency)
      end
    end

    # Only compare amounts directly when both currencies match.
    # Cross-currency differences require conversion accounting.

    def bank_difference_amounts
      @bank_difference_amounts ||= begin
        totals = empty_amounts

        comparable_swifts = confirmed_swifts.select do |swift|
          swift.bank&.currency.present? &&
          swift.currency.to_s == swift.bank.currency.to_s &&
          swift.deposited_amount.present?
        end

        comparable_swifts.each do |swift|
          currency = normalize_currency(swift.currency)
          next unless totals.key?(currency)

          totals[currency] += (
            decimal(swift.amount) - decimal(swift.deposited_amount)
            )
        end

        totals
      end
    end

    def bank_reconciliation_summary
      {
        confirmed_swifts: confirmed_swifts.size,
        missing_deposited_amounts: missing_bank_amount_swifts.size,
        cross_currency_count: cross_currency_bank_swifts.size,
        directly_comparable_count: confirmed_swifts.count do |swift|
          swift.bank&.currency.present? &&
          swift.currency.to_s == swift.bank.currency.to_s &&
          swift.deposited_amount.present?
        end
      }
    end

    # ==========================================================
    # CUSTOMER BALANCE
    #
    # CI invoice value - confirmed non-advance Swift amount
    #
    # Aggregate estimate, not invoice-level allocation.
    # ==========================================================

    def estimated_outstanding_amounts
      @estimated_outstanding_amounts ||= begin
        invoices = invoice_amounts
        receipts = confirmed_balance_amounts

        CURRENCIES.index_with do |currency|
          [
            invoices[currency] - receipts[currency],
            BigDecimal("0")
          ].max
        end
      end
    end

    def customer_credit_amounts
      @customer_credit_amounts ||= begin
        invoices = invoice_amounts
        receipts = confirmed_balance_amounts

        CURRENCIES.index_with do |currency|
          [
            receipts[currency] - invoices[currency],
            BigDecimal("0")
          ].max
        end
      end
    end

    def financial_data_complete?
      missing_ci_invoice_values.empty? &&
      unknown_pi_currencies.empty? &&
      unknown_swift_currencies.empty?
    end

    # ==========================================================
    # DATA QUALITY
    # ==========================================================

    def missing_ci_invoice_values
      cis.select { |ci| ci.balance_payment.nil? }
    end

    def missing_ci_issue_dates
      cis.select { |ci| ci.issue_date.blank? }
    end

    def missing_pi_issue_dates
      pis.select { |pi| pi.issue_date.blank? }
    end

    def missing_pi_total_prices
      pis.select { |pi| pi.total_price.nil? }
    end

    def unknown_pi_currencies
      pis.reject do |pi|
        CURRENCIES.include?(pi.currency.to_s)
      end
    end

    def unknown_swift_currencies
      swifts.reject do |swift|
        CURRENCIES.include?(swift.currency.to_s)
      end
    end

    def unknown_bank_currencies
      confirmed_swifts.select do |swift|
        !CURRENCIES.include?(normalize_currency(swift.bank&.currency))
      end
    end

    def missing_confirm_dates
      confirmed_swifts.select { |swift| swift.confirm_at.blank? }
    end

    def project_pi_anomalies
      @pis_by_project_id.select { |_project_id, project_pis| project_pis.size > 1 }
    end

    def data_quality
      {
        missing_ci_invoice_values: missing_ci_invoice_values,
        missing_ci_issue_dates: missing_ci_issue_dates,
        missing_pi_issue_dates: missing_pi_issue_dates,
        missing_pi_total_prices: missing_pi_total_prices,

        unknown_pi_currencies: unknown_pi_currencies,
        unknown_swift_currencies: unknown_swift_currencies,
        unknown_bank_currencies: unknown_bank_currencies,

        conflicting_swifts: conflicting_swifts,
        missing_confirm_dates: missing_confirm_dates,
        missing_bank_amount_swifts: missing_bank_amount_swifts,

        multiple_pis_per_project: project_pi_anomalies
      }
    end

    def data_quality_counts
      data_quality.transform_values do |value|
        value.is_a?(Hash) ? value.size : value.size
      end
    end

    # ==========================================================
    # PROJECT SUMMARIES
    # ==========================================================

    def project_summaries
      @project_summaries ||= projects.map do |project|
        project_pis = @pis_by_project_id[project.id] || []

        project_pi_ids = project_pis.map(&:id)

        project_cis = cis.select do |ci|
          ci.project_id == project.id ||
          project_pi_ids.include?(ci.pi_id)
        end.uniq(&:id)

        project_ci_ids = project_cis.map(&:id)

        project_bookings = @bookings_by_project_id[project.id] || []

        project_swifts = swifts.select do |swift|
          swift.project_id == project.id ||
          project_ci_ids.include?(swift.ci_id)
        end

        project_confirmed = project_swifts.select do |swift|
          swift.confirmed == true && swift.rejected != true
        end

        project_invoice_values = sum_by_currency(project_cis) do |ci|
          [pi_currency(ci), ci.balance_payment]
        end

        project_receipts = swift_amounts(
          project_confirmed,
          :amount,
          ->(swift) { swift.currency }
          )

        project_advance = swift_amounts(
          project_confirmed.select { |swift| swift.advance == true },
          :amount,
          ->(swift) { swift.currency }
          )

        project_balance = swift_amounts(
          project_confirmed.reject { |swift| swift.advance == true },
          :amount,
          ->(swift) { swift.currency }
          )

        {
          project: project,
          pi: project_pis.first,
          pis: project_pis,
          pi_count: project_pis.size,

          cis: project_cis,
          bookings: project_bookings,
          swifts: project_swifts,

          status: project_status(project),

          invoice_amounts: project_invoice_values,
          invoice_values_complete: project_cis.none? { |ci| ci.balance_payment.nil? },

          confirmed_receipts: project_receipts,
          confirmed_advance_receipts: project_advance,
          confirmed_balance_receipts: project_balance,

          booking_count: project_bookings.size,

          container_quantity: project_bookings.sum { |b| decimal(b.quantity) },
          containers_filled: project_bookings.sum { |b| decimal(b.filled) },
          containers_picked_up: project_bookings.sum { |b| decimal(b.picked_up) },

          ci_count: project_cis.size,
          ci_net_weight: project_cis.sum { |ci| decimal(ci.net_weight) },
          ci_gross_weight: project_cis.sum { |ci| decimal(ci.gross_weight) },

          receipt_count: project_swifts.size,
          confirmed_receipt_count: project_confirmed.size
        }
      end
    end

    # ==========================================================
    # MONTHLY CHARTS
    # ==========================================================

    # Invoice chart uses the CI issue_date.
    # Missing issue dates are flagged rather than guessed.

    def monthly_invoice_series
      monthly_currency_series(
        cis,
        date: ->(ci) { ci.issue_date },
        amount: ->(ci) { ci.balance_payment },
        currency: ->(ci) { pi_currency(ci) }
        )
    end

    def monthly_pi_series
      monthly_currency_series(
        pis,
        date: ->(pi) { pi.issue_date },
        amount: ->(pi) { pi.total_price },
        currency: ->(pi) { pi.currency }
        )
    end

    # Collections use the actual confirmation date.
    # This is separate from the existing DSO calculation.

    def monthly_collection_series
      monthly_currency_series(
        confirmed_swifts,
        date: ->(swift) { swift.confirm_at },
        amount: ->(swift) { swift.amount },
        currency: ->(swift) { swift.currency }
        )
    end

    def monthly_bank_credit_series
      monthly_currency_series(
        confirmed_swifts,
        date: ->(swift) { swift.confirm_at },
        amount: ->(swift) { swift.deposited_amount },
        currency: ->(swift) { swift.bank&.currency }
        )
    end

    def monthly_net_weight_series
      monthly_single_series(
        cis,
        date: ->(ci) { ci.issue_date },
        amount: ->(ci) { ci.net_weight },
        label: "CI Net Weight"
        )
    end

    def monthly_periods
      @monthly_periods ||= begin
        last_month = as_of.beginning_of_month

        @months.times.map do |offset|
          last_month << (@months - offset - 1)
        end
      end
    end

    # ==========================================================
    # ACTIVITY TIMELINE
    # ==========================================================

    def activity_events
      events = []

      pis.each do |pi|
        event_date = pi.issue_date.presence || pi.created_at

        description = [
          pi.number,
          pi.product,
          (pi.issue_date.blank? ? "Issue date missing; using record creation date" : nil)
        ].compact.join(" · ")

        add_event(
          events,
          event_date,
          "Proforma invoice",
          description,
          :pi,
          pi
          )
      end

      projects.each do |project|
        add_event(
          events,
          project.created_at,
          "Project opened",
          "Project #{project.number}",
          :project,
          project
          )
      end

      cis.each do |ci|
        amount_description =
        if ci.balance_payment.nil?
          "Invoice value missing"
        else
          "#{ci.balance_payment} #{pi_currency(ci)}"
        end

        event_date = ci.issue_date.presence || ci.created_at

        description = [
          ci.number,
          amount_description,
          (ci.issue_date.blank? ? "Issue date missing; using record creation date" : nil)
        ].compact.join(" · ")

        add_event(
          events,
          event_date,
          "Commercial invoice",
          description,
          :ci,
          ci
          )
      end

      swifts.each do |swift|
        add_event(
          events,
          swift.created_at,
          "Swift submitted",
          "#{swift.amount} #{swift.currency}",
          :swift,
          swift
          )

        if swift.confirmed == true
          bank_currency = swift.bank&.currency

          deposited_description =
          if swift.deposited_amount.nil?
            "Bank deposit amount missing"
          else
            "Bank credited #{swift.deposited_amount} #{bank_currency}"
          end

          add_event(
            events,
            swift.confirm_at,
            "Swift confirmed",
            deposited_description,
            :swift_confirmation,
            swift
            )
        end

        if swift.rejected == true
          add_event(
            events,
            swift.rejected_at,
            "Swift rejected",
            "#{swift.amount} #{swift.currency}",
            :swift_rejection,
            swift
            )
        end
      end

      bookings.each do |booking|
        add_event(
          events,
          booking.created_at,
          "Booking created",
          "Booking #{booking.number} · #{booking.quantity} containers",
          :booking,
          booking
          )

        # Only add actual date/time values. Some similarly named
        # booking fields are Boolean status flags.

        BOOKING_DATE_FIELDS.each do |attribute, title|
          next unless booking.respond_to?(attribute)

          value = booking.public_send(attribute)
          next unless value.respond_to?(:strftime)

          add_event(
            events,
            value,
            title,
            "Booking #{booking.number}",
            :booking_milestone,
            booking
            )
        end
      end

      events.sort_by do |event|
        event[:occurred_at] || Time.at(0)
      end.reverse
    end

    # ==========================================================
    # PRIVATE HELPERS
    # ==========================================================

    private

    def normalize_currency(value)
      value.to_s.downcase
    end

    def empty_amounts
      CURRENCIES.index_with { BigDecimal("0") }
    end

    def decimal(value)
      return BigDecimal("0") if value.nil?

      BigDecimal(value.to_s)
    rescue ArgumentError, TypeError
      BigDecimal("0")
    end

    def sum_by_currency(records)
      totals = empty_amounts

      records.each do |record|
        currency, amount = yield(record)
        currency = normalize_currency(currency)

        next unless totals.key?(currency)

        totals[currency] += decimal(amount)
      end

      totals
    end

    def swift_amounts(records, attribute, currency_method)
      totals = empty_amounts

      records.each do |swift|
        currency = currency_method.call(swift).to_s

        next unless totals.key?(currency)

        totals[currency] += decimal(swift.public_send(attribute))
      end

      totals
    end

    def pi_currency(ci)
      @pi_by_id[ci.pi_id]&.currency
    end

    def project_status(project)
      return "Logistics completed" if project.logistics_done?
      return "Sales completed" if project.sales_done?
      return "Purchase started" if project.started?

      "In progress"
    end

    def monthly_currency_series(records, date:, amount:, currency:)
      buckets = monthly_periods.index_with { empty_amounts }

      records.each do |record|
        record_date = date.call(record)
        next if record_date.blank?

        month = record_date.to_date.beginning_of_month
        next unless buckets.key?(month)

        currency_key = currency.call(record).to_s
        next unless CURRENCIES.include?(currency_key)

        buckets[month][currency_key] += decimal(amount.call(record))
      end

      {
        labels: monthly_periods.map { |month| month.strftime("%b %Y") },

        datasets: CURRENCIES.map do |currency_key|
          {
            label: currency_key.titleize,
            data: monthly_periods.map do |month|
              buckets[month][currency_key].to_f
            end
          }
        end
      }
    end

    def monthly_single_series(records, date:, amount:, label:)
      buckets = monthly_periods.index_with { BigDecimal("0") }

      records.each do |record|
        record_date = date.call(record)
        next if record_date.blank?

        month = record_date.to_date.beginning_of_month
        next unless buckets.key?(month)

        buckets[month] += decimal(amount.call(record))
      end

      {
        labels: monthly_periods.map { |month| month.strftime("%b %Y") },

        datasets: [
          {
            label: label,
            data: monthly_periods.map { |month| buckets[month].to_f }
          }
        ]
      }
    end

    def add_event(events, date, title, description, kind, record)
      return unless date.respond_to?(:strftime)

      occurred_at =
      if date.respond_to?(:in_time_zone)
        date.in_time_zone
      else
        date.to_time
      end

      events << {
        occurred_at: occurred_at,
        title: title,
        description: description,
        kind: kind,
        record: record
      }
    end
  end
end
