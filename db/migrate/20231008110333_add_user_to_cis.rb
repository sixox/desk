class AddUserToCis < ActiveRecord::Migration[7.0]
  def change
    add_reference :cis, :user, foreign_key: true
  end
end
