class CreateManualEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :manual_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :occurred_at, null: false    # date and time of the manual entry/exit
      t.boolean :is_entry, null: false        # true if it's a manual "entry", false if "exit"
      t.text :description
      t.timestamps
    end
  end
end
