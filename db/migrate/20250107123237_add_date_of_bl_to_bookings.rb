class AddDateOfBlToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :date_of_bl, :date
  end
end
