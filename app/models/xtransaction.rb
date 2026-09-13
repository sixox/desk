class Xtransaction < ApplicationRecord

    # ==================================================
    # ASSOCIATIONS
    # ==================================================

    belongs_to :xaccount

    belongs_to :currency

    belongs_to :transactionable,
    polymorphic: true


    # ==================================================
    # VALIDATIONS
    # ==================================================

    validates :xaccount,
    presence: true

    validates :currency,
    presence: true

    validates :transactionable,
    presence: true

    validates :debit_amount,
    numericality: {
      greater_than_or_equal_to: 0,
      only_integer: true
    }

    validates :credit_amount,
    numericality: {
      greater_than_or_equal_to: 0,
      only_integer: true
    }

    validates :balance_before_transaction,
    numericality: {
      only_integer: true
    }

    validates :balance_after_transaction,
    numericality: {
      only_integer: true
    }


    # ==================================================
    # GENERIC CREATE
    #
    # Any model can use:
    #
    # Xtransaction.create_for!(
    #   transactionable: object,
    #   user: current_user,
    #   entries: [
    #     {
    #       xaccount: account,
    #       currency: currency,
    #       debit_amount: 1000,
    #       credit_amount: 0
    #     }
    #   ]
    # )
    #
    # Also supports:
    #
    # {
    #   xaccount_id: 10,
    #   currency_id: 2,
    #   debit_amount: 1000,
    #   credit_amount: 0
    # }
    #
    # ==================================================

    def self.create_for!(
      transactionable:,
      entries:,
      user: nil,
      note: nil
      )

    timestamp =
    Time.current

    username =
    transaction_username(user)

    entries =
    normalize_entries(entries)

    return if entries.empty?


    note ||=
    generic_creation_note(
      transactionable: transactionable,
      entries: entries,
      username: username,
      timestamp: timestamp
      )


      # ------------------------------------------------
      # Aggregate entries first.
      #
      # If a future model sends multiple entries for the
      # same account/currency, they are handled together.
      #
      # ------------------------------------------------

      effects =
      aggregate_effects(entries)


      effects
      .sort_by { |key, _effect| key.to_s }
      .each do |key, effect|

        xaccount_id,
        currency_id =
        key

        xaccount =
        xaccount_map(
          [xaccount_id]
          )[xaccount_id]

        currency =
        currency_map(
          [currency_id]
          )[currency_id]


        create_ledger_entry!(
          xaccount: xaccount,
          currency: currency,
          transactionable: transactionable,
          debit_amount: effect[:debit],
          credit_amount: effect[:credit],
          note: note
          )

      end

    end


    # ==================================================
    # GENERIC UPDATE / RECONCILIATION
    #
    # OLD entries describe the accounting effect that
    # already exists in the ledger.
    #
    # NEW entries describe what the accounting effect
    # should be after the model was updated.
    #
    # The method calculates:
    #
    #     new effect - old effect
    #
    # per account and currency.
    #
    # Only the difference is recorded.
    #
    # ==================================================

    def self.reconcile!(
      transactionable:,
      old_entries:,
      new_entries:,
      user: nil,
      note: nil
      )

    old_entries =
    normalize_entries(old_entries)

    new_entries =
    normalize_entries(new_entries)


      # ------------------------------------------------
      # Combine all old/new effects by:
      #
      # account + currency
      #
      # ------------------------------------------------

      old_effects =
      aggregate_effects(old_entries)

      new_effects =
      aggregate_effects(new_entries)


      keys =
      old_effects.keys |
      new_effects.keys


      changes = []


      keys
      .sort_by { |key| key.to_s }
      .each do |key|

        old_effect =
        old_effects[key] ||
        zero_effect

        new_effect =
        new_effects[key] ||
        zero_effect


        debit_difference =
        new_effect[:debit] -
        old_effect[:debit]

        credit_difference =
        new_effect[:credit] -
        old_effect[:credit]


        next if
        debit_difference.zero? &&
        credit_difference.zero?


        changes << {
          key: key,
          debit_difference: debit_difference,
          credit_difference: credit_difference,
          old_debit: old_effect[:debit],
          new_debit: new_effect[:debit],
          old_credit: old_effect[:credit],
          new_credit: new_effect[:credit]
        }

      end


      # ------------------------------------------------
      # Absolutely no accounting change.
      #
      # Do NOT create an Xtransaction.
      # ------------------------------------------------

      return if changes.empty?


      timestamp =
      Time.current

      username =
      transaction_username(user)


      note ||=
      generic_update_note(
        transactionable: transactionable,
        changes: changes,
        username: username,
        timestamp: timestamp
        )


      # ------------------------------------------------
      # Bulk-load all required accounts and currencies.
      #
      # This replaces repeated Xaccount.find and
      # Currency.find calls.
      # ------------------------------------------------

      account_ids =
      changes.map do |change|
        change[:key][0]
      end.uniq


      currency_ids =
      changes.map do |change|
        change[:key][1]
      end.uniq


      accounts =
      xaccount_map(account_ids)

      currencies =
      currency_map(currency_ids)


      # ------------------------------------------------
      # Create only the required ledger differences.
      #
      # IMPORTANT:
      #
      # We keep the same accounting behavior as before,
      # but combine debit/credit differences for the
      # same account/currency into one ledger row.
      #
      # ------------------------------------------------

      changes
      .sort_by { |change| change[:key].to_s }
      .each do |change|

        xaccount_id,
        currency_id =
        change[:key]


        xaccount =
        accounts.fetch(
          xaccount_id
          )


        currency =
        currencies.fetch(
          currency_id
          )


        debit_difference =
        change[:debit_difference]

        credit_difference =
        change[:credit_difference]


          # ------------------------------------------------
          # Calculate the actual delta to the ledger.
          #
          # A positive debit difference means debit.
          # A negative debit difference means credit.
          #
          # A positive credit difference means credit.
          # A negative credit difference means debit.
          #
          # ------------------------------------------------

          debit_amount =
          debit_difference > 0 ?
          debit_difference :
          0

          credit_amount =
          debit_difference < 0 ?
          debit_difference.abs :
          0


          if credit_difference > 0

            credit_amount +=
            credit_difference

          elsif credit_difference < 0

            debit_amount +=
            credit_difference.abs

          end


          next if
          debit_amount.zero? &&
          credit_amount.zero?


          create_ledger_entry!(
            xaccount: xaccount,
            currency: currency,
            transactionable: transactionable,
            debit_amount: debit_amount,
            credit_amount: credit_amount,
            note: note
            )

        end

      end


    # ==================================================
    # INITIAL LEDGER ENTRY
    #
    # Generic helper used by create_for! and reconcile!.
    #
    # The Xaccount row is locked before calculating the
    # balance. This is safer than locking only the latest
    # Xtransaction because an account with no transactions
    # yet would otherwise have nothing to lock.
    #
    # ==================================================

    def self.create_ledger_entry!(
      xaccount:,
      currency:,
      transactionable:,
      debit_amount:,
      credit_amount:,
      note:
      )

    debit_amount =
    debit_amount.to_i

    credit_amount =
    credit_amount.to_i


    return if
    debit_amount.zero? &&
    credit_amount.zero?


      # ------------------------------------------------
      # Lock the account itself.
      #
      # This serializes balance calculation for this
      # account inside the current database transaction.
      # ------------------------------------------------

      locked_account =
      Xaccount
      .lock
      .find(
        xaccount.id
        )


      # ------------------------------------------------
      # Find the latest transaction after the account
      # has been locked.
      # ------------------------------------------------

      previous_transaction =
      where(
        xaccount_id: locked_account.id
        )
      .order(id: :desc)
      .first


      balance_before =
      previous_transaction
      &.balance_after_transaction
      .to_i


      balance_after =
      balance_before -
      debit_amount +
      credit_amount


      create!(
        xaccount: locked_account,
        currency: currency,
        transactionable: transactionable,
        debit_amount: debit_amount,
        credit_amount: credit_amount,
        balance_before_transaction: balance_before,
        balance_after_transaction: balance_after,
        note: note
        )

    end


    # ==================================================
    # NORMALIZE ENTRIES
    #
    # Supported:
    #
    # {
    #   xaccount: account,
    #   currency: currency,
    #   debit_amount: 1000,
    #   credit_amount: 0
    # }
    #
    # Also:
    #
    # {
    #   xaccount_id: 10,
    #   currency_id: 2,
    #   debit_amount: 1000,
    #   credit_amount: 0
    # }
    #
    # IMPORTANT:
    #
    # If objects are already supplied, no query is made.
    #
    # If IDs are supplied, accounts/currencies are loaded
    # in bulk instead of doing find inside every iteration.
    #
    # ==================================================

    def self.normalize_entries(entries)

      raw_entries =
      Array(entries)
      .filter_map do |entry|

        next if entry.blank?

        entry.symbolize_keys

      end


      return [] if raw_entries.empty?


      # ------------------------------------------------
      # Collect IDs that need loading.
      # ------------------------------------------------

      xaccount_ids =
      raw_entries
      .filter_map do |entry|

        next if entry[:xaccount].present?

        entry[:xaccount_id].presence

      end
      .map(&:to_i)
      .uniq


      currency_ids =
      raw_entries
      .filter_map do |entry|

        next if entry[:currency].present?

        entry[:currency_id].presence

      end
      .map(&:to_i)
      .uniq


      accounts =
      xaccount_map(
        xaccount_ids
        )


      currencies =
      currency_map(
        currency_ids
        )


      raw_entries.filter_map do |entry|

        xaccount =
        entry[:xaccount]


        if xaccount.blank? &&
         entry[:xaccount_id].present?

         xaccount =
         accounts[
          entry[:xaccount_id].to_i
        ]

      end


      next if xaccount.blank?


      currency =
      entry[:currency]


      if currency.blank? &&
       entry[:currency_id].present?

       currency =
       currencies[
        entry[:currency_id].to_i
      ]

    end


        # ------------------------------------------------
        # If currency was not explicitly supplied, use
        # the currency belonging to the account.
        #
        # The account is expected to already have currency
        # loaded when possible.
        # ------------------------------------------------

        currency ||=
        if xaccount.association(:currency).loaded?

          xaccount.currency

        else

          currency_id =
          xaccount.currency_id

          currency_map(
            [currency_id]
            )[currency_id]

        end


        next if currency.blank?


        debit_amount =
        entry[:debit_amount].to_i

        credit_amount =
        entry[:credit_amount].to_i


        next if
        debit_amount.zero? &&
        credit_amount.zero?


        {
          xaccount: xaccount,
          currency: currency,
          debit_amount: debit_amount,
          credit_amount: credit_amount
        }

      end

    end


    # ==================================================
    # BULK ACCOUNT LOAD
    # ==================================================

    def self.xaccount_map(ids)

      ids =
      Array(ids)
      .compact
      .map(&:to_i)
      .uniq


      return {} if ids.empty?


      Xaccount
      .where(id: ids)
      .includes(:currency)
      .index_by(&:id)

    end


    # ==================================================
    # BULK CURRENCY LOAD
    # ==================================================

    def self.currency_map(ids)

      ids =
      Array(ids)
      .compact
      .map(&:to_i)
      .uniq


      return {} if ids.empty?


      Currency
      .where(id: ids)
      .index_by(&:id)

    end


    # ==================================================
    # AGGREGATE EFFECTS
    #
    # Multiple entries for the same account/currency
    # are combined before comparison.
    #
    # ==================================================

    def self.aggregate_effects(entries)

      entries.each_with_object(
        Hash.new do |hash, key|
          hash[key] = zero_effect
        end
        ) do |entry, result|

        key =
        [
          entry[:xaccount].id,
          entry[:currency].id
        ]


        result[key][:debit] +=
        entry[:debit_amount].to_i


        result[key][:credit] +=
        entry[:credit_amount].to_i

      end

    end


    # ==================================================
    # ZERO EFFECT
    # ==================================================

    def self.zero_effect

      {
        debit: 0,
        credit: 0
      }

    end


    # ==================================================
    # USER NAME
    # ==================================================

    def self.transaction_username(user)

      return "System" if user.blank?


      user.try(:name).presence ||
      user.try(:full_name).presence ||
      user.try(:email).presence ||
      "User ##{user.id}"

    end


    # ==================================================
    # GENERIC CREATE NOTE
    # ==================================================

    def self.generic_creation_note(
      transactionable:,
      entries:,
      username:,
      timestamp:
      )

    transaction_name =
    transactionable.class.name


    transaction_id =
    transactionable.id


    details =
    entries.map do |entry|

      account =
      entry[:xaccount]

      currency =
      entry[:currency]


      "Account #{account.id} " \
      "(#{account.number}) " \
      "#{currency&.name}: " \
      "debit #{entry[:debit_amount].to_i}, " \
      "credit #{entry[:credit_amount].to_i}"

    end.join("; ")


    "User: #{username} created " \
    "#{transaction_name} ##{transaction_id} " \
    "at #{timestamp.strftime('%Y-%m-%d %H:%M:%S')}. " \
    "#{details}."

  end


    # ==================================================
    # GENERIC UPDATE NOTE
    # ==================================================

    def self.generic_update_note(
      transactionable:,
      changes:,
      username:,
      timestamp:
      )

    transaction_name =
    transactionable.class.name


    transaction_id =
    transactionable.id


    details =
    changes.map do |change|

      xaccount_id,
      currency_id =
      change[:key]


      parts = []


      if change[:old_debit] !=
       change[:new_debit]

       parts <<
       "debit from " \
       "#{change[:old_debit]} " \
       "to #{change[:new_debit]}"

     end


     if change[:old_credit] !=
       change[:new_credit]

       parts <<
       "credit from " \
       "#{change[:old_credit]} " \
       "to #{change[:new_credit]}"

     end


     "Account #{xaccount_id}, " \
     "Currency #{currency_id}: " \
     "#{parts.join(', ')}"

   end.join("; ")


   "User: #{username} edited " \
   "#{transaction_name} ##{transaction_id} " \
   "at #{timestamp.strftime('%Y-%m-%d %H:%M:%S')}: " \
   "#{details}."

  end

  def transactionable_link
    return nil unless transactionable

    Rails.application.routes.url_helpers.polymorphic_path(transactionable)
  rescue ActionController::UrlGenerationError
    nil
  end

  def transactionable_name
    transactionable_type.underscore.humanize
  end

end