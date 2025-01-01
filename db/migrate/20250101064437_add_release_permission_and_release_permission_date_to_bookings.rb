class AddReleasePermissionAndReleasePermissionDateToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :release_permission, :boolean
    add_column :bookings, :release_permission_date, :date
  end
end
