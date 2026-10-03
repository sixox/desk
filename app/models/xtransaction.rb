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
  # MOVEMENT
  # ==================================================

  def movement?
    transactionable.is_a?(MoneyMovement) ||
      transactionable.is_a?(ExchangeMovement)
  end


  def movement
    return unless movement?

    transactionable
  end


  # ==================================================
  # MOVEMENT SYNC
  # ==================================================

  def self.sync_movement!(
    movement:,
    old_entry: nil,
    user: nil,
    note: nil
  )
    if old_entry.blank?
      create_for_movement!(
        movement: movement,
        user: user,
        note: note
      )
    else
      reconcile_movement!(
        movement: movement,
        old_entry: old_entry,
        user: user,
        note: note
      )
    end
  end


  # ==================================================
  # CREATE ONE MOVEMENT TRANSACTION
  #
  # One movement -> one base Xtransaction.
  #
  # Additional Xtransactions can later be used for
  # corrections/reconciliations.
  # ==================================================

  def self.create_for_movement!(
    movement:,
    user: nil,
    note: nil
  )
    unless movement.is_a?(MoneyMovement) ||
           movement.is_a?(ExchangeMovement)

      raise ArgumentError,
            "movement must be MoneyMovement or ExchangeMovement"
    end

    movement.reload

    entry = movement.accounting_entry

    return if
      entry[:debit_amount].to_i.zero? &&
      entry[:credit_amount].to_i.zero?

    note ||=
      movement_creation_note(
        movement: movement,
        user: user
      )

    create_ledger_entry!(
      xaccount: movement.xaccount,
      currency: movement.currency,
      transactionable: movement,
      debit_amount: entry[:debit_amount],
      credit_amount: entry[:credit_amount],
      note: note
    )
  end


  # ==================================================
  # RECONCILE ONE MOVEMENT
  #
  # The original Xtransaction is never modified.
  #
  # Instead:
  #
  #   old debit   -> credit adjustment
  #   old credit  -> debit adjustment
  #   new debit   -> debit adjustment
  #   new credit  -> credit adjustment
  #
  # This also handles changing the Xaccount.
  # ==================================================

  def self.reconcile_movement!(
    movement:,
    old_entry:,
    user: nil,
    note: nil
  )
    unless movement.is_a?(MoneyMovement) ||
           movement.is_a?(ExchangeMovement)

      raise ArgumentError,
            "movement must be MoneyMovement or ExchangeMovement"
    end

    old_entry =
      normalize_entry(
        old_entry
      )

    new_entry =
      normalize_entry(
        movement.accounting_entry
      )


    # ------------------------------------------------
    # No change
    # ------------------------------------------------

    return if old_entry == new_entry


    # ------------------------------------------------
    # Build accounting effects
    # ------------------------------------------------

    old_key = [
      old_entry[:xaccount_id],
      old_entry[:currency_id]
    ]

    new_key = [
      new_entry[:xaccount_id],
      new_entry[:currency_id]
    ]


    effects =
      Hash.new do |hash, key|
        hash[key] = {
          debit: 0,
          credit: 0
        }
      end


    # ------------------------------------------------
    # Reverse old effect
    # ------------------------------------------------

    effects[old_key][:debit] +=
      old_entry[:credit_amount]

    effects[old_key][:credit] +=
      old_entry[:debit_amount]


    # ------------------------------------------------
    # Apply new effect
    # ------------------------------------------------

    effects[new_key][:debit] +=
      new_entry[:debit_amount]

    effects[new_key][:credit] +=
      new_entry[:credit_amount]


    # ------------------------------------------------
    # Convert effects to changes
    # ------------------------------------------------

    changes = []

    effects.each do |key, effect|

      next if
        effect[:debit].zero? &&
        effect[:credit].zero?

      changes << {
        xaccount_id: key[0],
        currency_id: key[1],
        debit_amount: effect[:debit],
        credit_amount: effect[:credit]
      }
    end


    return if changes.empty?


    # ------------------------------------------------
    # Note
    # ------------------------------------------------

    note ||=
      movement_update_note(
        movement: movement,
        user: user
      )


    # ------------------------------------------------
    # Create adjustment transactions
    # ------------------------------------------------

    changes.each do |change|

      xaccount =
        Xaccount
          .includes(:currency)
          .find(
            change[:xaccount_id]
          )

      currency =
        Currency.find(
          change[:currency_id]
        )


      create_ledger_entry!(
        xaccount: xaccount,
        currency: currency,
        transactionable: movement,
        debit_amount: change[:debit_amount],
        credit_amount: change[:credit_amount],
        note: note
      )
    end


    changes
  end


  # ==================================================
  # LEDGER ENTRY
  # ==================================================
  #
  # SEND:
  #
  #   debit
  #   balance decreases
  #
  # RECEIVE:
  #
  #   credit
  #   balance increases
  #
  # The account is locked before calculating the
  # balance so concurrent transactions cannot use
  # the same previous balance.
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


    Xaccount.transaction(requires_new: true) do

      # ------------------------------------------------
      # Lock account before calculating balance
      # ------------------------------------------------

      locked_account =
        Xaccount
          .lock
          .find(
            xaccount.id
          )


      # ------------------------------------------------
      # Latest transaction belonging to THIS account
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


      # ------------------------------------------------
      # Accounting rule
      #
      # Debit  = money leaving account
      # Credit = money entering account
      # ------------------------------------------------

      balance_after =
        balance_before -
        debit_amount +
        credit_amount


      # ------------------------------------------------
      # Create transaction
      # ------------------------------------------------

      create!(
        xaccount: locked_account,
        currency: currency,
        transactionable: transactionable,

        debit_amount: debit_amount,
        credit_amount: credit_amount,

        balance_before_transaction:
          balance_before,

        balance_after_transaction:
          balance_after,

        note: note
      )
    end
  end


  # ==================================================
  # ENTRY HELPERS
  # ==================================================

  def self.normalize_entry(entry)
    entry =
      entry.symbolize_keys

    {
      xaccount_id:
        entry[:xaccount_id].to_i,

      currency_id:
        entry[:currency_id].to_i,

      debit_amount:
        entry[:debit_amount].to_i,

      credit_amount:
        entry[:credit_amount].to_i
    }
  end


  # ==================================================
  # MOVEMENT CREATION NOTE
  # ==================================================

  def self.movement_creation_note(
    movement:,
    user:
  )
    username =
      transaction_username(
        user
      )


    movement_name =
      movement.class.name


    side =
      movement.respond_to?(:accounting_side) ?
        movement.accounting_side :
        "unknown"


    direction =
      movement.respond_to?(:direction) ?
        movement.direction :
        "unknown"


    "User: #{username} created " \
    "#{movement_name} ##{movement.id} " \
    "(#{direction} / #{side}) " \
    "at #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}. " \
    "Debit: #{movement.debit_amount}. " \
    "Credit: #{movement.credit_amount}."
  end


  # ==================================================
  # MOVEMENT UPDATE NOTE
  # ==================================================

  def self.movement_update_note(
    movement:,
    user:
  )
    username =
      transaction_username(
        user
      )


    movement_name =
      movement.class.name


    side =
      movement.respond_to?(:accounting_side) ?
        movement.accounting_side :
        "unknown"


    direction =
      movement.respond_to?(:direction) ?
        movement.direction :
        "unknown"


    "User: #{username} updated " \
    "#{movement_name} ##{movement.id} " \
    "(#{direction} / #{side}) " \
    "at #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}. " \
    "Adjustment - Debit: #{movement.debit_amount}. " \
    "Credit: #{movement.credit_amount}."
  end


  # ==================================================
  # USER
  # ==================================================

  def self.transaction_username(user)
    return "System" if user.blank?

    user.try(:name).presence ||
      user.try(:full_name).presence ||
      user.try(:email).presence ||
      "User ##{user.id}"
  end


  # ==================================================
  # DISPLAY HELPERS
  # ==================================================

  def transactionable_link
    return nil unless transactionable

    record =
      if transactionable.respond_to?(:movable) &&
         transactionable.movable.present?

        transactionable.movable
      else
        transactionable
      end

    Rails
      .application
      .routes
      .url_helpers
      .polymorphic_path(record)

  rescue ActionController::UrlGenerationError,
         NoMethodError

    nil
  end


  def transactionable_name
    return nil unless transactionable

    record =
      if transactionable.respond_to?(:movable) &&
         transactionable.movable.present?

        transactionable.movable
      else
        transactionable
      end

    record.class.name
      .underscore
      .humanize
  end


  def transactionable_display_id
    return nil unless transactionable

    if transactionable.respond_to?(:movable) &&
       transactionable.movable.present?

      transactionable.movable.id
    else
      transactionable.id
    end
  end
end