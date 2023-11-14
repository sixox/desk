class CreateClients < ActiveRecord::Migration[7.0]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :company
      t.string :email
      t.string :phone
      t.string :received_from
      t.string :preferred_connection
      t.string :product
      t.string :country
      t.string :port
      t.string :packing
      t.text :details
      t.string :status
      t.date :update_status_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
