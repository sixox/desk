class AddUserToPis < ActiveRecord::Migration[7.0]
  def change
    add_reference :pis, :user, foreign_key: true
  end
end
