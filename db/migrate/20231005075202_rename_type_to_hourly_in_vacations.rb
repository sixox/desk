class RenameTypeToHourlyInVacations < ActiveRecord::Migration[7.0]
  def change
    rename_column :vacations, :type, :hourly
  end
end
