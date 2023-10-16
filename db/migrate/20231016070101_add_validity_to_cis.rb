class AddValidityToCis < ActiveRecord::Migration[7.0]
  def change
    add_column :cis, :validity, :integer
  end
end
