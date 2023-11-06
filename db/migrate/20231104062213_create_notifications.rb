class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.boolean :is_read
      t.string :link_to_action
      t.integer :counter

      t.timestamps
    end
  end
end
