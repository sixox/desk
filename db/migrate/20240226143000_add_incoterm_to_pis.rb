class AddIncotermToPis < ActiveRecord::Migration[7.0]
  def change
    add_column :pis, :incoterm, :string
  end
end
