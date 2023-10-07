class ChangeIsManagerToBoolean < ActiveRecord::Migration[7.0]
  def change
        change_column :users, :is_manager, :boolean

  end
end
