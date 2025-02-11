class AddIndexToPisProduct < ActiveRecord::Migration[7.0]
  def change
     add_index :pis, :product
     add_index :pis, [:product, :issue_date]
  end
end
