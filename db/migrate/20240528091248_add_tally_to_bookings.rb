class AddTallyToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :tally, :boolean
    add_column :bookings, :declaration, :boolean
  end
end
