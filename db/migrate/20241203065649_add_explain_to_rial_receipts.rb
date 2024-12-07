class AddExplainToRialReceipts < ActiveRecord::Migration[7.0]
  def change
    add_column :rial_receipts, :explain, :text
  end
end
