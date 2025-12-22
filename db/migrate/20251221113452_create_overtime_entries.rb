class CreateOvertimeEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :overtime_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false            # date of the overtime work
      t.decimal :hours, precision: 5, scale: 2, null: false   # number of overtime hours
      t.boolean :confirmed, default: true  # by default, consider overtime approved
      t.text :reason
      t.timestamps
    end
  end
end
