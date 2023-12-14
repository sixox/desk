class RenameStatusToCurrencySwifts < ActiveRecord::Migration[7.0]
  def change
            rename_column :swifts, :status, :currency

  end
end
