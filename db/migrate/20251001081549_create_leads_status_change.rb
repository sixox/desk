class CreateLeadsStatusChange < ActiveRecord::Migration[7.0]
  def change
    create_table :lead_status_changes do |t|
      t.references :lead, null: false, foreign_key: true
      t.string  :from_status
      t.string  :to_status,   null: false
      t.bigint  :changed_by_id   # optional (users table)
      t.datetime :occurred_at,   null: false

      t.decimal :offered_amount, precision: 12, scale: 2
      t.text    :note

      t.timestamps
    end

    add_index :lead_status_changes, [:lead_id, :occurred_at]
  end
end
