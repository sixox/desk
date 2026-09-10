# app/models/xtransaction.rb

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

  validates :debit_amount,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validates :credit_amount,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validate :only_one_side
  validate :balanced_amounts


  # ==================================================
  # TYPES
  # ==================================================

  def debit?
    debit_amount.to_i > 0
  end


  def credit?
    credit_amount.to_i > 0
  end


  # ==================================================
  # SIGNED AMOUNT
  # ==================================================

  def signed_amount
    debit_amount.to_i - credit_amount.to_i
  end


  # ==================================================
  # CREATE DEBIT TRANSACTION
  # ==================================================

  def self.create_debit!(
    account:,
    amount:,
    transactionable:
  )
    amount = amount.to_i

    raise ArgumentError,
          "Debit amount must be greater than zero" if amount <= 0

    debit_before =
      account.balance

    debit_after =
      debit_before + amount

    account.update!(
      debit_amount:
        account.debit_amount.to_i + amount
    )

    create!(
      xaccount: account,
      currency: account.currency,
      transactionable: transactionable,

      debit_amount: amount,
      credit_amount: 0,

      balance_before_transaction: debit_before,
      balance_after_transaction: debit_after
    )
  end


  # ==================================================
  # CREATE CREDIT TRANSACTION
  # ==================================================

  def self.create_credit!(
    account:,
    amount:,
    transactionable:
  )
    amount = amount.to_i

    raise ArgumentError,
          "Credit amount must be greater than zero" if amount <= 0

    credit_before =
      account.balance

    credit_after =
      credit_before - amount

    account.update!(
      credit_amount:
        account.credit_amount.to_i + amount
    )

    create!(
      xaccount: account,
      currency: account.currency,
      transactionable: transactionable,

      debit_amount: 0,
      credit_amount: amount,

      balance_before_transaction: credit_before,
      balance_after_transaction: credit_after
    )
  end


  # ==================================================
  # CREATE TRANSFER TRANSACTIONS
  # ==================================================

  def self.create_for_transfer!(
    transfer:
  )
    sender_account =
      transfer.sender_account

    receiver_account =
      transfer.receiver_account

    sender_amount =
      transfer.sender_total.to_i

    receiver_amount =
      transfer.receiver_total.to_i


    raise ArgumentError,
          "Sender account is required" unless sender_account

    raise ArgumentError,
          "Receiver account is required" unless receiver_account


    if sender_account.id == receiver_account.id
      raise ArgumentError,
            "Sender and receiver accounts must be different"
    end


    if sender_amount <= 0
      raise ArgumentError,
            "Sender total must be greater than zero"
    end


    if receiver_amount <= 0
      raise ArgumentError,
            "Receiver total must be greater than zero"
    end


    ActiveRecord::Base.transaction do

      debit_transaction =
        create_debit!(
          account: sender_account,
          amount: sender_amount,
          transactionable: transfer
        )


      credit_transaction =
        create_credit!(
          account: receiver_account,
          amount: receiver_amount,
          transactionable: transfer
        )


      [
        debit_transaction,
        credit_transaction
      ]
    end
  end


  # ==================================================
  # REVERSE TRANSACTION
  # ==================================================

  def reverse!(
    transactionable:
  )
    ActiveRecord::Base.transaction do

      account = xaccount


      # ----------------------------------------------
      # Reverse DEBIT
      #
      # Original:
      #   debit + amount
      #
      # Reversal:
      #   credit + amount
      # ----------------------------------------------

      if debit?

        amount =
          debit_amount.to_i

        before =
          account.balance


        account.update!(
          credit_amount:
            account.credit_amount.to_i + amount
        )


        self.class.create!(
          xaccount: account,
          currency: currency,
          transactionable: transactionable,

          debit_amount: 0,
          credit_amount: amount,

          balance_before_transaction: before,
          balance_after_transaction: before - amount
        )


      # ----------------------------------------------
      # Reverse CREDIT
      #
      # Original:
      #   credit + amount
      #
      # Reversal:
      #   debit + amount
      # ----------------------------------------------

      elsif credit?

        amount =
          credit_amount.to_i

        before =
          account.balance


        account.update!(
          debit_amount:
            account.debit_amount.to_i + amount
        )


        self.class.create!(
          xaccount: account,
          currency: currency,
          transactionable: transactionable,

          debit_amount: amount,
          credit_amount: 0,

          balance_before_transaction: before,
          balance_after_transaction: before + amount
        )
      end
    end
  end


  # ==================================================
  # PRIVATE VALIDATIONS
  # ==================================================

  private


  def only_one_side
    if debit_amount.to_i > 0 &&
       credit_amount.to_i > 0

      errors.add(
        :base,
        "A transaction cannot have both debit and credit"
      )
    end


    if debit_amount.to_i == 0 &&
       credit_amount.to_i == 0

      errors.add(
        :base,
        "A transaction must have either debit or credit"
      )
    end
  end


  def balanced_amounts
    if debit_amount.to_i < 0 ||
       credit_amount.to_i < 0

      errors.add(
        :base,
        "Debit and credit amounts cannot be negative"
      )
    end
  end
end