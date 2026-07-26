class CreateZahras < ActiveRecord::Migration[7.0]
  def change
    create_table :zahras do |t|
      t.string :name
      t.string :family
      t.integer :phone

      t.timestamps
    end
  end
end
