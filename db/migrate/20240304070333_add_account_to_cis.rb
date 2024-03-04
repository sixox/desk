class AddAccountToCis < ActiveRecord::Migration[7.0]
  def change
    add_reference :cis, :account, null: true, foreign_key: true
  end
end
