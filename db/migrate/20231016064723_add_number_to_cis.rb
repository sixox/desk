class AddNumberToCis < ActiveRecord::Migration[7.0]
  def change
    add_column :cis, :number, :string
  end
end
