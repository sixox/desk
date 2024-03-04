class AddAccountToPis < ActiveRecord::Migration[7.0]
  def change
    add_reference :pis, :account, null: true, foreign_key: true
  end
end
