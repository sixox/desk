class CreateMessageStatuses < ActiveRecord::Migration[7.0]
 def change
  create_table :message_statuses do |t|
    t.references :message, null: false, foreign_key: true
    t.references :user, null: false, foreign_key: true
    t.string :status, default: 'unread'

    t.timestamps
  end
end
end
