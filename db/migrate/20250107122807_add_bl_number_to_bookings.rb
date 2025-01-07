class AddBlNumberToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :bl_number, :string
  end
end
