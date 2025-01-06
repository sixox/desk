class AddInspectionAndFreightPriceToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :inspection, :boolean
    add_column :bookings, :freight_price, :integer
  end
end
