class AddFactoryOrderDateToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :factory_order_date, :date
    add_column :bookings, :pick_up_date, :date
    add_column :bookings, :stuffing, :boolean
    add_column :bookings, :custom_clearance, :boolean
    add_column :bookings, :custom_submission_date, :date
    add_column :bookings, :vessel_etd, :date



  end
end
