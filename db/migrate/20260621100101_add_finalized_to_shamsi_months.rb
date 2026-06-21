class AddFinalizedToShamsiMonths < ActiveRecord::Migration[7.0]
  def change
    add_column :shamsi_months, :finalized, :boolean, default: false
  end
end
