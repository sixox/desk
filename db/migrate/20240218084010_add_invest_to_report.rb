class AddInvestToReport < ActiveRecord::Migration[7.0]
  def change
    add_column :reports, :invest, :boolean
  end
end
