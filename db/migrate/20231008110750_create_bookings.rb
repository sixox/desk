class CreateBookings < ActiveRecord::Migration[7.0]
  def change
    create_table :bookings do |t|
      t.string :number
      t.string :line
      t.string :forwarder
      t.string :pod
      t.string :container_type
      t.boolean :have_flexi
      t.integer :quantity
      t.date :validation_date
      t.integer :free_time
      t.string :status
      t.integer :picked_up
      t.string :payment_status
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
