class CreateUserManagerMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :user_manager_mappings do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.references :manager, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

  end
end
