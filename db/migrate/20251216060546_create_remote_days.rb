class CreateRemoteDays < ActiveRecord::Migration[7.0]
  def change
    create_table :remote_days do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.boolean :confirmed, default: true, null: false
      t.text :text

      t.timestamps
    end
  end
end
