class AddIsMarketingToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :is_marketing, :boolean
  end
end
