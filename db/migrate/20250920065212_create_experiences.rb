class CreateExperiences < ActiveRecord::Migration[7.0]
  def change
    create_table :experiences do |t|
      t.string :subject
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
