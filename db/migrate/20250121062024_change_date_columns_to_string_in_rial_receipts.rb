class ChangeDateColumnsToStringInRialReceipts < ActiveRecord::Migration[7.0]
  def change
    change_column :rial_receipts, :check_date, :string
    change_column :rial_receipts, :payment_date, :string
  end
end
