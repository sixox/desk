class AddFounderIdToRialReceipts < ActiveRecord::Migration[7.0]
  def change
    add_column :rial_receipts, :founder_id, :integer
  end
end
