class AddOccurredOnToManualEntries < ActiveRecord::Migration[7.0]
  def change
    add_column :manual_entries, :occurred_on, :date

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE manual_entries
          SET occurred_on = date(occurred_at)
          WHERE occurred_on IS NULL
        SQL
      end
    end

    change_column_null :manual_entries, :occurred_on, false

    add_index :manual_entries, [:user_id, :occurred_on, :is_entry],
              unique: true,
              name: "idx_manual_entries_user_day_kind"
  end
end
