class AddCommissionAndAgentToPi < ActiveRecord::Migration[7.0]
  def change
    add_column :pis, :commission, :integer
    add_column :pis, :agent, :string
  end
end
