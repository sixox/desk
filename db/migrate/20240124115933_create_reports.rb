class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports do |t|
      t.string :subject
      t.text :details
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
