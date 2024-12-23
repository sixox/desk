class CreateMessageObservers < ActiveRecord::Migration[7.0]
 def change
    create_table :message_observers do |t|
      t.references :message, null: false, foreign_key: true
      t.references :observer, null: false, foreign_key: { to_table: :users }
      t.boolean :read, default: false

      t.timestamps
    end
  end
end
