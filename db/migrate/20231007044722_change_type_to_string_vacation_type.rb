class ChangeTypeToStringVacationType < ActiveRecord::Migration[7.0]
  def change
        change_column :vacations, :vacation_type, :string
  end
end
