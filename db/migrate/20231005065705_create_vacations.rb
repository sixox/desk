class CreateVacations < ActiveRecord::Migration[7.0]
  def change
    create_table :vacations do |t|
      t.string :type
      t.string :status
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :confirm
      t.references :user, null: false, foreign_key: true
      t.text :details
      t.text :comment

      t.timestamps
    end
  end
end
