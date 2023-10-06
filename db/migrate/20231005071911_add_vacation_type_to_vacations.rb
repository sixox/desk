class AddVacationTypeToVacations < ActiveRecord::Migration[7.0]
  def change
    add_column :vacations, :vacation_type, :integer
  end
end
