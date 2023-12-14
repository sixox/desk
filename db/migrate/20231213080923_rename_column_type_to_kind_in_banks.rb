class RenameColumnTypeToKindInBanks < ActiveRecord::Migration[7.0]
  def change
        rename_column :banks, :type, :kind

  end
end
