class CreateReleaseRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :release_requests do |t|
      t.references :booking, null: false, foreign_key: true
      t.boolean :confirmed
      t.datetime :confirmed_at
      t.text :note

      t.timestamps
    end
  end
end
