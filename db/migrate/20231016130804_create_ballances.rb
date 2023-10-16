class CreateBallances < ActiveRecord::Migration[7.0]
  def change
    create_table :ballances do |t|
      t.string :number
      t.string :status
      t.string :name
      t.string :product

      t.timestamps
    end
  end
end
