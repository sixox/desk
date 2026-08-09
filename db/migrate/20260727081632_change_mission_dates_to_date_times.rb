class ChangeMissionDatesToDateTimes < ActiveRecord::Migration[7.0]
  def up
    change_column :missions, :start_at, :datetime
    change_column :missions, :end_at, :datetime
  end

  def down
    change_column :missions, :start_at, :date
    change_column :missions, :end_at, :date
  end
end