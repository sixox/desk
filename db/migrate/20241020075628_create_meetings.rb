class CreateMeetings < ActiveRecord::Migration[7.0]
  def change
    create_table :meetings do |t|
      t.references :secretary, null: false, foreign_key: true
      t.string :title
      t.date :date
      t.text :participants
      t.string :guests
      t.text :details
      t.boolean :is_secret

      t.timestamps
    end
  end
end
