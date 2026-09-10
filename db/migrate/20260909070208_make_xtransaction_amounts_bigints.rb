class MakeXtransactionAmountsBigints < ActiveRecord::Migration[7.0]
  def change
    change_column :xtransactions,
                  :debit_amount,
                  :integer,
                  limit: 8

    change_column :xtransactions,
                  :credit_amount,
                  :integer,
                  limit: 8

    change_column :xtransactions,
                  :balance_before_transaction,
                  :integer,
                  limit: 8

    change_column :xtransactions,
                  :balance_after_transaction,
                  :integer,
                  limit: 8
  end
end


