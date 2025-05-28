class AddWeightToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :weight, :integer
  end
end
