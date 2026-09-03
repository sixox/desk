class ChangeCreditAmountToBigint < ActiveRecord::Migration[7.0]
  def change
    change_column :credits, :amount, :bigint
  end
end
