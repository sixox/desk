class AddFollowerToClients < ActiveRecord::Migration[7.0]
  def change
    add_column :clients, :follower, :string
  end
end
