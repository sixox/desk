class CreateLeadTask < ActiveRecord::Migration[7.0]
  def change
    create_table :lead_tasks do |t|
      t.references :lead, null: false, foreign_key: true
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.string  :title, null: false
      t.date    :due_on
      t.integer :status, null: false, default: 0 # 0=open, 1=done
      t.datetime :completed_at
      t.text    :notes

      t.timestamps
    end

    add_index :lead_tasks, [:lead_id, :status]
    add_index :lead_tasks, :due_on
  end
end
