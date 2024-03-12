class ChangeIntegerToBigInt < ActiveRecord::Migration[7.0]
  def change
    change_column :swifts, :amount, :bigint
    change_column :swifts, :deposited_amount, :bigint
    change_column :banks, :account_balance, :bigint
    change_column :deposits, :amount, :bigint
    change_column :transfers, :withdraw_amount, :bigint
    change_column :transfers, :deposited_amount, :bigint
  end
end
