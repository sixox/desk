
# app/services/customer_360/portfolio.rb

module Customer360
  class Portfolio
    CURRENCIES = Overview::CURRENCIES.map(&:downcase).freeze
    DEFAULT_MONTHS = 12

    attr_reader :customers, :pis, :cis, :projects, :swifts, :bookings

    def initialize(customers: Customer.all, as_of: Date.current, months: DEFAULT_MONTHS)
      @customers = customers.to_a
      @as_of = as_of.to_date
      @months = months.to_i.clamp(1, 36)

      load_records
    end

    def load_records
      customer_ids = customers.map(&:id)

      @pis = Pi.where(customer_id: customer_ids).includes(:project).to_a
      @pi_by_id = pis.index_by(&:id)

      pi_ids = pis.map(&:id)

      @cis = Ci.where(pi_id: pi_ids).includes(:pi, :project).to_a

      project_ids = (
        pis.map(&:project_id) + cis.map(&:project_id)
      ).compact.uniq

      @projects = Project.where(id: project_ids).to_a
      @bookings = Booking.where(project_id: project_ids).to_a

      ci_ids = cis.map(&:id)
      swift_conditions = []

      swift_conditions << Swift.where(project_id: project_ids) if project_ids.any?
      swift_conditions << Swift.where(ci_id: ci_ids) if ci_ids.any?

      swift_relation =
        if swift_conditions.empty?
          Swift.none
        else
          swift_conditions.reduce { |left, right| left.or(right) }
        end

      @swifts = swift_relation
        .includes(:bank, :ci, :project)
        .distinct
        .to_a

      @pis_by_customer = pis.group_by(&:customer_id)
      @cis_by_pi = cis.group_by(&:pi_id)

      @projects_by_id = projects.index_by(&:id)
      @bookings_by_project = bookings.group_by(&:project_id)
      @swifts_by_project = swifts.group_by(&:project_id)
      @swifts_by_ci = swifts.group_by(&:ci_id)
    end

    # ==========================================================
    # PER-CUSTOMER FIGURES
    # ==========================================================

    def customer_summaries
      @customer_summaries ||= customers.map do |customer|
        customer_pis = @pis_by_customer[customer.id] || []

        customer_cis = customer_pis.flat_map do |pi|
          @cis_by_pi[pi.id] || []
        end.uniq(&:id)

        customer_project_ids = (
          customer_pis.map(&:project_id) +
          customer_cis.map(&:project_id)
        ).compact.uniq

        customer_projects = customer_project_ids.filter_map do |id|
          @projects_by_id[id]
        end

        customer_ci_ids = customer_cis.map(&:id)

        customer_swifts = (
          customer_project_ids.flat_map { |id| @swifts_by_project[id] || [] } +
          customer_ci_ids.flat_map { |id| @swifts_by_ci[id] || [] }
        ).uniq(&:id)

        customer_bookings = customer_project_ids.flat_map do |id|
          @bookings_by_project[id] || []
        end.uniq(&:id)

        confirmed = customer_swifts.select do |swift|
          swift.confirmed == true && swift.rejected != true
        end

        pending = customer_swifts.select do |swift|
          swift.confirmed != true && swift.rejected != true
        end

        rejected = customer_swifts.select do |swift|
          swift.rejected == true && swift.confirmed != true
        end

        conflicting = customer_swifts.select do |swift|
          swift.confirmed == true && swift.rejected == true
        end

        advances = confirmed.select { |swift| swift.advance == true }
        balances = confirmed.reject { |swift| swift.advance == true }

        invoices = invoice_totals(customer_cis)
        offers = pi_totals(customer_pis)
        confirmed_receipts = swift_totals(confirmed, :amount)
        advance_receipts = swift_totals(advances, :amount)
        balance_receipts = swift_totals(balances, :amount)
        pending_receipts = swift_totals(pending, :amount)
        bank_credits = bank_totals(confirmed)

        bank_differences = bank_difference_totals(confirmed)

        outstanding = CURRENCIES.index_with do |currency|
          [
            invoices[currency] - balance_receipts[currency],
            BigDecimal("0")
          ].max
        end

        all_records = [
          customer,
          *customer_pis,
          *customer_cis,
          *customer_projects,
          *customer_bookings,
          *customer_swifts
        ]

        {
          customer: customer,

          pis: customer_pis,
          cis: customer_cis,
          projects: customer_projects,
          bookings: customer_bookings,
          swifts: customer_swifts,

          pi_count: customer_pis.size,
          project_count: customer_projects.size,
          ci_count: customer_cis.size,
          booking_count: customer_bookings.size,

          active_project_count: customer_projects.count do |project|
            !project.logistics_done?
          end,

          completed_project_count: customer_projects.count(&:logistics_done?),

          pi_offer_amounts: offers,
          invoice_amounts: invoices,

          confirmed_receipt_amounts: confirmed_receipts,
          confirmed_advance_amounts: advance_receipts,
          confirmed_balance_amounts: balance_receipts,
          pending_receipt_amounts: pending_receipts,

          bank_credited_amounts: bank_credits,
          bank_difference_amounts: bank_differences,

          outstanding_amounts: outstanding,

          confirmed_swift_count: confirmed.size,
          pending_swift_count: pending.size,
          rejected_swift_count: rejected.size,
          conflicting_swift_count: conflicting_swifts.size,
          missing_invoice_count: customer_cis.count do |ci|
            ci.balance_payment.nil?
          end,

          cross_currency_swift_count: confirmed.count do |swift|
            swift.bank&.currency.present? &&
              normalize_currency(swift.currency) != normalize_currency(swift.bank.currency)
          end,

          net_weight: customer_cis.sum { |ci| decimal(ci.net_weight) },

          latest_activity: all_records.filter_map(&:updated_at).max
        }
      end
    end

    # ==========================================================
    # COMPANY SUMMARY
    # ==========================================================

    def summary
      rows = customer_summaries

      {
        customer_count: rows.size,

        customers_with_projects: rows.count do |row|
          row[:project_count].positive?
        end,

        customers_with_debit: rows.count do |row|
          row[:outstanding_amounts].values.any?(&:positive?)
        end,

        customers_with_pending_receipts: rows.count do |row|
          row[:pending_receipt_amounts].values.any?(&:positive?)
        end,

        project_count: projects.size,

        active_project_count: projects.count do |project|
          !project.logistics_done?
        end,

        completed_project_count: projects.count(&:logistics_done?),

        pi_count: pis.size,
        ci_count: cis.size,
        booking_count: bookings.size,
        swift_count: swifts.size,

        missing_invoice_count: cis.count do |ci|
          ci.balance_payment.nil?
        end,

        confirmed_swift_count: confirmed_swifts.size,
        pending_swift_count: pending_swifts.size,
        rejected_swift_count: rejected_swifts.size,

        pi_offer_amounts: aggregate_rows(:pi_offer_amounts),
        invoice_amounts: aggregate_rows(:invoice_amounts),
        advance_amounts: aggregate_rows(:confirmed_advance_amounts),
        balance_receipts: aggregate_rows(:confirmed_balance_amounts),
        pending_receipts: aggregate_rows(:pending_receipt_amounts),
        bank_credited: aggregate_rows(:bank_credited_amounts),
        bank_differences: aggregate_rows(:bank_difference_amounts),
        outstanding_amounts: aggregate_rows(:outstanding_amounts)
      }
    end

    # ==========================================================
    # CUSTOMER ACCOUNTS NEEDING ATTENTION
    # ==========================================================

    def customers_needing_attention(limit: 12)
      customer_summaries
        .select do |row|
          row[:outstanding_amounts].values.any?(&:positive?) ||
            row[:pending_receipt_amounts].values.any?(&:positive?)
        end
        .sort_by { |row| row[:latest_activity] || Time.at(0) }
        .reverse
        .first(limit)
    end

    # ==========================================================
    # MONTHLY MONEY FLOW
    # ==========================================================

    def monthly_periods
      @monthly_periods ||= begin
        last_month = @as_of.beginning_of_month

        @months.times.map do |offset|
          last_month << (@months - offset - 1)
        end
      end
    end

    def monthly_money_flow
      invoices = monthly_buckets
      customer_receipts = monthly_buckets
      bank_credits = monthly_buckets

      cis.each do |ci|
        next if ci.issue_date.blank? || ci.balance_payment.nil?

        pi = @pi_by_id[ci.pi_id]
        next unless pi

        currency = normalize_currency(pi.currency)
        next unless CURRENCIES.include?(currency)

        month = ci.issue_date.to_date.beginning_of_month
        next unless invoices.key?(month)

        invoices[month][currency] += decimal(ci.balance_payment)
      end

      confirmed_swifts.each do |swift|
        next if swift.confirm_at.blank?

        month = swift.confirm_at.to_date.beginning_of_month
        next unless customer_receipts.key?(month)

        customer_currency = normalize_currency(swift.currency)

        if CURRENCIES.include?(customer_currency)
          customer_receipts[month][customer_currency] += decimal(swift.amount)
        end

        bank_currency = normalize_currency(swift.bank&.currency)

        if CURRENCIES.include?(bank_currency)
          bank_credits[month][bank_currency] += decimal(swift.deposited_amount)
        end
      end

      {
        labels: monthly_periods.map { |month| month.strftime("%b %Y") },

        currencies: CURRENCIES.index_with do |currency|
          {
            invoices: monthly_periods.map { |month| invoices[month][currency].to_f },
            customer_received: monthly_periods.map { |month| customer_receipts[month][currency].to_f },
            bank_credited: monthly_periods.map { |month| bank_credits[month][currency].to_f }
          }
        end
      }
    end

    # ==========================================================
    # HELPERS
    # ==========================================================

    private

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


    def empty_amounts
      CURRENCIES.index_with { BigDecimal("0") }
    end

    def decimal(value)
      return BigDecimal("0") if value.nil?

      BigDecimal(value.to_s)
    rescue ArgumentError, TypeError
      BigDecimal("0")
    end

    def normalize_currency(value)
      value.to_s.downcase
    end

    def invoice_totals(records)
      totals = empty_amounts

      records.each do |ci|
        currency = normalize_currency(@pi_by_id[ci.pi_id]&.currency)
        next unless totals.key?(currency)

        totals[currency] += decimal(ci.balance_payment)
      end

      totals
    end

    def pi_totals(records)
      totals = empty_amounts

      records.each do |pi|
        currency = normalize_currency(pi.currency)
        next unless totals.key?(currency)

        totals[currency] += decimal(pi.total_price)
      end

      totals
    end

    def swift_totals(records, attribute)
      totals = empty_amounts

      records.each do |swift|
        currency = normalize_currency(swift.currency)
        next unless totals.key?(currency)

        totals[currency] += decimal(swift.public_send(attribute))
      end

      totals
    end

    def bank_totals(records)
      totals = empty_amounts

      records.each do |swift|
        currency = normalize_currency(swift.bank&.currency)
        next unless totals.key?(currency)

        totals[currency] += decimal(swift.deposited_amount)
      end

      totals
    end

    def bank_difference_totals(records)
      totals = empty_amounts

      records.each do |swift|
        swift_currency = normalize_currency(swift.currency)
        bank_currency = normalize_currency(swift.bank&.currency)

        next unless swift_currency == bank_currency
        next unless totals.key?(swift_currency)
        next if swift.deposited_amount.nil?

        totals[swift_currency] += (
          decimal(swift.amount) - decimal(swift.deposited_amount)
        )
      end

      totals
    end

    def aggregate_rows(attribute)
      totals = empty_amounts

      customer_summaries.each do |row|
        row.fetch(attribute).each do |currency, amount|
          totals[currency] += amount
        end
      end

      totals
    end

    def monthly_buckets
      monthly_periods.index_with { empty_amounts }
    end
  end
end
