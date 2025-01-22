class AddStarToMessageStatuses < ActiveRecord::Migration[7.0]
  def change
    add_column :message_statuses, :star, :boolean, default: false
  end
end
