class AddDepositedAmountToSwifts < ActiveRecord::Migration[7.0]
  def change
    add_column :swifts, :deposited_amount, :integer
  end
end
