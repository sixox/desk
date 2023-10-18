class AddNumberToScis < ActiveRecord::Migration[7.0]
  def change
    add_column :scis, :number, :string
  end
end
