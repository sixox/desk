class AddVesselNameToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :vessel_name, :string
  end
end
