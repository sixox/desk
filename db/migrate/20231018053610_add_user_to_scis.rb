class AddUserToScis < ActiveRecord::Migration[7.0]
  def change
    add_reference :scis, :user, null: false, foreign_key: true
  end
end
