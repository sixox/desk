class RenameAccountIdToXaccountIdInCredits < ActiveRecord::Migration[7.0]
  def change
        rename_column :credits, :account_id, :xaccount_id

  end
end
