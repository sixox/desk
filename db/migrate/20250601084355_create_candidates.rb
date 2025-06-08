class CreateCandidates < ActiveRecord::Migration[7.0]
  def change
    create_table :candidates do |t|
      t.string :name
      t.string :phone
      t.string :role
      t.string :password_digest

      t.timestamps
    end
  end
end
