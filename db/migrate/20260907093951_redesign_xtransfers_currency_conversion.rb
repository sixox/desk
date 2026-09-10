class RedesignXtransfersCurrencyConversion < ActiveRecord::Migration[7.0]
  def change
    # ------------------------------------------------------------
    # Rename existing amount columns
    # ------------------------------------------------------------

    if column_exists?(:xtransfers, :sent_amount) &&
       !column_exists?(:xtransfers, :sender_amount)
      rename_column :xtransfers, :sent_amount, :sender_amount
    end

    if column_exists?(:xtransfers, :receive_amount) &&
       !column_exists?(:xtransfers, :receiver_amount)
      rename_column :xtransfers, :receive_amount, :receiver_amount
    end

    # ------------------------------------------------------------
    # Sender conversion
    # ------------------------------------------------------------

    unless column_exists?(:xtransfers, :sender_exchange_rate)
      add_column :xtransfers, :sender_exchange_rate,
                 :decimal, precision: 20, scale: 10
    end

    unless column_exists?(:xtransfers, :sender_amount_to)
      add_column :xtransfers, :sender_amount_to,
                 :decimal, precision: 20, scale: 5
    end

    # ------------------------------------------------------------
    # Receiver conversion
    # ------------------------------------------------------------

    unless column_exists?(:xtransfers, :receiver_exchange_rate)
      add_column :xtransfers, :receiver_exchange_rate,
                 :decimal, precision: 20, scale: 10
    end

    unless column_exists?(:xtransfers, :receiver_amount_to)
      add_column :xtransfers, :receiver_amount_to,
                 :decimal, precision: 20, scale: 5
    end

    # ------------------------------------------------------------
    # Destination currencies
    #
    # sender_currency_id       = sender account currency
    # sender_to_currency_id    = receiver account currency
    #
    # receiver_currency_id     = receiver account currency
    # receiver_to_currency_id  = sender account currency
    # ------------------------------------------------------------

    unless column_exists?(:xtransfers, :sender_to_currency_id)
      add_column :xtransfers, :sender_to_currency_id, :integer
    end

    unless column_exists?(:xtransfers, :receiver_to_currency_id)
      add_column :xtransfers, :receiver_to_currency_id, :integer
    end

    # ------------------------------------------------------------
    # Totals
    # ------------------------------------------------------------

    unless column_exists?(:xtransfers, :sender_total)
      add_column :xtransfers, :sender_total,
                 :decimal, precision: 20, scale: 5, default: 0
    end

    unless column_exists?(:xtransfers, :receiver_total)
      add_column :xtransfers, :receiver_total,
                 :decimal, precision: 20, scale: 5, default: 0
    end

    # ------------------------------------------------------------
    # Existing exchange_rate -> both new rates
    #
    # This preserves existing transfer data.
    # ------------------------------------------------------------

    if column_exists?(:xtransfers, :exchange_rate)
      execute <<~SQL
        UPDATE xtransfers
        SET
          sender_exchange_rate = exchange_rate,
          receiver_exchange_rate = exchange_rate
        WHERE exchange_rate IS NOT NULL
      SQL

      remove_column :xtransfers, :exchange_rate
    end

    # ------------------------------------------------------------
    # Foreign keys for the two new currency columns
    # ------------------------------------------------------------

    unless foreign_key_exists?(
      :xtransfers,
      :currencies,
      column: :sender_to_currency_id
    )
      add_foreign_key :xtransfers,
                      :currencies,
                      column: :sender_to_currency_id
    end

    unless foreign_key_exists?(
      :xtransfers,
      :currencies,
      column: :receiver_to_currency_id
    )
      add_foreign_key :xtransfers,
                      :currencies,
                      column: :receiver_to_currency_id
    end
  end
end