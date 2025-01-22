class AddStarToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :star, :boolean, default: false
  end
end
