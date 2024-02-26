class AddToleranceToPis < ActiveRecord::Migration[7.0]
  def change
    add_column :pis, :tolerance, :integer
  end
end
