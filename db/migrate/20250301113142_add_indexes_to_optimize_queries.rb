class AddIndexesToOptimizeQueries < ActiveRecord::Migration[7.0]
  def change
    add_index :cis, :sent
    add_index :cis, [:pi_id, :sent]
    add_index :pis, :currency
    add_index :pis, [:customer_id, :currency]
  end
end
