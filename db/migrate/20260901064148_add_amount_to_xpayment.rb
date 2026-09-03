class AddAmountToXpayment < ActiveRecord::Migration[7.0]
  def change
    add_column :xpayments, :amount, :bigint
  end
end
