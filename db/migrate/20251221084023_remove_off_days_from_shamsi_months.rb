class RemoveOffDaysFromShamsiMonths < ActiveRecord::Migration[7.0]
  def change
    remove_column :shamsi_months, :off_days, :integer
  end
end
