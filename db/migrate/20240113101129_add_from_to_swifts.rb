class AddFromToSwifts < ActiveRecord::Migration[7.0]
  def change
    add_column :swifts, :from, :string
  end
end
