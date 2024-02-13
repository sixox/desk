class AddUserToHistoryPriceTables < ActiveRecord::Migration[7.0]
  def change
    add_reference :history_price_tables, :user, null: false, foreign_key: true
  end
end
