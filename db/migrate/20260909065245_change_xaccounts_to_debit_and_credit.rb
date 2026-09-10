class ChangeXaccountsToDebitAndCredit < ActiveRecord::Migration[7.0]
  def up
    add_column :xaccounts, :debit_amount, :bigint, default: 0, null: false
    add_column :xaccounts, :credit_amount, :bigint, default: 0, null: false
    remove_column :xaccounts, :amount
  end

  def down
    add_column :xaccounts, :amount, :bigint, default: 0, null: false
    remove_column :xaccounts, :debit_amount
    remove_column :xaccounts, :credit_amount
  end
end