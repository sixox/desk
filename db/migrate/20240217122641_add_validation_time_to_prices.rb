class AddValidationTimeToPrices < ActiveRecord::Migration[7.0]
  def change
    add_column :prices, :validation_time, :datetime
  end
end
