class AddCooConfirmedAndCooConfirmedAtToTransfers < ActiveRecord::Migration[7.0]
  def change
    add_column :transfers, :coo_confirmed, :boolean
    add_column :transfers, :coo_confirmed_at, :date
  end
end
