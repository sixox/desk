class CreateGeneratedDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :generated_documents do |t|
      t.string :name
      t.string :file
      t.references :user, null: false, foreign_key: true
      t.references :pi, null: false, foreign_key: true
      t.references :ci, null: false, foreign_key: true

      t.timestamps
    end
  end
end
