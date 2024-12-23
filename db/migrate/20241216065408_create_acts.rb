class CreateActs < ActiveRecord::Migration[7.0]
  def change
    create_table :acts do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action_type
      t.text :action_details

      t.timestamps
    end
  end
end
