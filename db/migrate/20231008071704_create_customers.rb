class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :nickname
      t.string :company

      t.timestamps
    end
  end
end
