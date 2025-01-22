class AddStarToMessageObservers < ActiveRecord::Migration[7.0]
  def change
    add_column :message_observers, :star, :boolean, default: false
  end
end
