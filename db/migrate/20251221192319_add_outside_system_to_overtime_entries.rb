class AddOutsideSystemToOvertimeEntries < ActiveRecord::Migration[7.0]
  def change
    add_column :overtime_entries, :outside_system, :boolean, null: false, default: false
  end
end
