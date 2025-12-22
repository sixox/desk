class CreateWdmsEmploeeMap < ActiveRecord::Migration[7.0]
  def change
    create_table :wdms_employee_mappings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :emp_code, null: false
      t.string :device_serial
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :wdms_employee_mappings, [:emp_code, :device_serial], unique: true
  end
end
