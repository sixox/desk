class CreateAssessments < ActiveRecord::Migration[7.0]
  def change
    create_table :assessments do |t|
      t.string :category
      t.integer :category_point
      t.string :criterion
      t.text :definition
      t.string :title

      t.timestamps
    end
  end
end
