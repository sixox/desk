class AddPaymentDoneToBookings < ActiveRecord::Migration[7.0]
  def change
    add_column :bookings, :payment_done, :boolean
  end
end
