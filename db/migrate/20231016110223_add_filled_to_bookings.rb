class AddFilledToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :filled, :integer
  end
end
