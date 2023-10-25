class AddIndexToUserRole < ActiveRecord::Migration[7.0]
  def change
        add_index :users, :role

  end
end
