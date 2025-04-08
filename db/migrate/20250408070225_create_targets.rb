class CreateTargets < ActiveRecord::Migration[7.0]
  def change
    create_table :targets do |t|
      t.references :kpi_list, null: false, foreign_key: true
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
