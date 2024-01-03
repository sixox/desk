class AddCheckedAtToBanks < ActiveRecord::Migration[7.0]
  def change
    add_column :banks, :checked_at, :datetime
  end
end
