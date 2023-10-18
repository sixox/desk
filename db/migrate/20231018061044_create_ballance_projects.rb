class CreateBallanceProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :ballance_projects do |t|
      t.integer :quantity
      t.references :ballance, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
