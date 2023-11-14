class AddQuantityToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :quantity, :integer
  end
end
