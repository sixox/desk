class AddUniqueIndexToOvertimeEntriesUserDate < ActiveRecord::Migration[7.0]
  def change
    def change
      add_index :overtime_entries, [:user_id, :date],
      unique: true,
      name: "idx_overtime_entries_user_day"
    end
  end
end
