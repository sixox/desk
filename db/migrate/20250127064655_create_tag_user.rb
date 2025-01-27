class CreateTagUser < ActiveRecord::Migration[7.0]
  def change
    create_table :message_tags do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :tag, null: false

      t.timestamps
    end

    # Ensure a user can add only one tag per message
    add_index :message_tags, [:message_id, :user_id], unique: true
  end
end
