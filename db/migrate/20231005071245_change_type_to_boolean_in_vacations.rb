class ChangeTypeToBooleanInVacations < ActiveRecord::Migration[7.0]
  def change
    change_column :vacations, :type, :boolean
  end
end
