class CreateUndoneActions < ActiveRecord::Migration[7.0]
  def change
    create_table :undone_actions do |t|
      t.references :quarterly_evaluation, null: false, foreign_key: true
      t.text :description
      t.integer :weight
      t.integer :point

      t.timestamps
    end
  end
end
