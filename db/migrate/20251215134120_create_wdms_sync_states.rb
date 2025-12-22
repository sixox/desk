# frozen_string_literal: true

class CreateWdmsSyncStates < ActiveRecord::Migration[7.0]
  def change
    create_table :wdms_sync_states do |t|
      t.string   :device_serial,    null: false
      t.datetime :last_occurred_at
      t.timestamps
    end

    add_index :wdms_sync_states, :device_serial, unique: true
  end
end
