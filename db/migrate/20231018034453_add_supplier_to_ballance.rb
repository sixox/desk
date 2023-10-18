class AddSupplierToBallance < ActiveRecord::Migration[7.0]
  def change
    add_reference :ballances, :supplier, null: false, foreign_key: true
  end
end
