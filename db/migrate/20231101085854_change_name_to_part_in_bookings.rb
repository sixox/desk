class ChangeNameToPartInBookings < ActiveRecord::Migration[7.0]
  def change
    rename_column :bookings, :name, :part
    change_column :bookings, :part, :integer
  end
end
