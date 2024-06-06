class ChangeCustomSubmissionDateToSendToLine < ActiveRecord::Migration[7.0]
  def change
      add_column :bookings, :send_to_line, :boolean, default: false
  end
end
