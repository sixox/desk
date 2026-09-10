class Addtoxacountsome < ActiveRecord::Migration[7.0]
  def change
    # -----------------------------------------------
    # Xtransactions
    # -----------------------------------------------

    rename_column :xtransactions,
                  :deposit_amount,
                  :debit_amount

    rename_column :xtransactions,
                  :withdrawal_amount,
                  :credit_amount

    # -----------------------------------------------
    # Xtransfers
    # -----------------------------------------------

    add_column :xtransfers, :sender_charge, :float, default: 0
    add_column :xtransfers, :receiver_charge, :float, default: 0

    add_column :xtransfers, :sender_total, :integer, default: 0
    add_column :xtransfers, :receiver_total, :integer, default: 0

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE xtransfers
          SET sender_total = COALESCE(sent_amount, 0),
              receiver_total = COALESCE(receive_amount, 0)
        SQL
      end
    end
  end
end
