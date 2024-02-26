class CreateLetterHeads < ActiveRecord::Migration[7.0]
  def change
    create_table :letter_heads do |t|
      t.string :name

      t.timestamps
    end
  end
end
