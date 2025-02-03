class AddSentToCis < ActiveRecord::Migration[7.0]
  def change
    add_column :cis, :sent, :boolean
  end
end
