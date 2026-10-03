class RemoveLegacyMoneyFieldsFromAccountingObjects < ActiveRecord::Migration[7.0]
  def change
    # ==========================================================
    # XTRANSFERS
    # ==========================================================

    remove_column :xtransfers, :sender_amount, :bigint
    remove_column :xtransfers, :receiver_amount, :bigint

    remove_column :xtransfers, :sender_account_id, :integer
    remove_column :xtransfers, :receiver_account_id, :integer

    remove_column :xtransfers, :sender_currency_id, :integer
    remove_column :xtransfers, :receiver_currency_id, :integer

    remove_column :xtransfers, :sender_charge, :bigint
    remove_column :xtransfers, :receiver_charge, :bigint

    remove_column :xtransfers, :sender_total, :bigint
    remove_column :xtransfers, :receiver_total, :bigint

    remove_column :xtransfers, :sender_exchange_rate, :float
    remove_column :xtransfers, :receiver_exchange_rate, :float

    remove_column :xtransfers, :sender_amount_to, :bigint
    remove_column :xtransfers, :receiver_amount_to, :bigint

    remove_column :xtransfers, :sender_to_currency_id, :integer
    remove_column :xtransfers, :receiver_to_currency_id, :integer


    # ==========================================================
    # XPAYMENTS
    # ==========================================================

    remove_column :xpayments, :sender_account_id, :integer
    remove_column :xpayments, :receiver_account_id, :integer

    remove_column :xpayments, :currency_id, :integer

    remove_column :xpayments, :sent_amount, :integer
    remove_column :xpayments, :received_amount, :integer


    # ==========================================================
    # REMITTANCES
    # ==========================================================

    remove_column :remittances, :sender_account_id, :integer
    remove_column :remittances, :receiver_account_id, :integer

    remove_column :remittances, :currency_id, :integer

    remove_column :remittances, :sent_amount, :bigint
    remove_column :remittances, :received_amount, :bigint


    # ==========================================================
    # EXCHANGES
    # ==========================================================

    remove_column :exchanges, :seller_account_id, :integer
    remove_column :exchanges, :buyer_account_id, :integer

    remove_column :exchanges, :sell_currency_id, :integer
    remove_column :exchanges, :buy_currency_id, :integer

    remove_column :exchanges, :exchange_rate, :float

    remove_column :exchanges, :sell_amount, :bigint
    remove_column :exchanges, :buy_amount, :bigint
  end
end