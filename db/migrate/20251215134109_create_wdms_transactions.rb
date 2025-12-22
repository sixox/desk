# frozen_string_literal: true

class CreateWdmsTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :wdms_transactions do |t|
      t.string   :device_serial, null: false
      t.string   :emp_code,      null: false
      t.datetime :occurred_at,   null: false
      t.string   :row_hash,      null: false
      t.text     :raw_payload
      t.timestamps
    end

    add_index :wdms_transactions, :row_hash, unique: true
    add_index :wdms_transactions, [:device_serial, :occurred_at]
    add_index :wdms_transactions, [:emp_code, :occurred_at]
  end
end
