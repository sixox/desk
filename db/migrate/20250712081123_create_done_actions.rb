class CreateDoneActions < ActiveRecord::Migration[7.0]
  def change
    create_table :done_actions do |t|
      t.references :quarterly_evaluation, null: false, foreign_key: true
      t.text :description
      t.integer :weight
      t.integer :point

      t.timestamps
    end
  end
end
