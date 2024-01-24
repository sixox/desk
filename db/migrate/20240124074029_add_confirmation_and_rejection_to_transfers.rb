class AddConfirmationAndRejectionToTransfers < ActiveRecord::Migration[7.0]
  def change
    add_column :transfers, :confirmed, :boolean
    add_column :transfers, :rejected, :boolean
    add_column :transfers, :confirmed_at, :datetime
    add_column :transfers, :rejected_at, :datetime
  end
end
