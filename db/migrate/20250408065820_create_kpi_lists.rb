class CreateKpiLists < ActiveRecord::Migration[7.0]
  def change
    create_table :kpi_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :period, null: false # 1 to 4 for seasons, 0 for full year

      t.timestamps
    end

    add_index :kpi_lists, [:user_id, :year, :period], unique: true
  end
end
