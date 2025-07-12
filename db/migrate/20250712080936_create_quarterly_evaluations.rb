class CreateQuarterlyEvaluations < ActiveRecord::Migration[7.0]
  def change
    create_table :quarterly_evaluations do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year
      t.integer :period
      t.text :comment
      t.references :kpi_list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
