class AddBallanceToScis < ActiveRecord::Migration[7.0]
  def change
    add_reference :scis, :ballance, null: false, foreign_key: true
  end
end
