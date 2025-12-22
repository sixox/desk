class AddAccountingConfirmToSalaryArchives < ActiveRecord::Migration[7.0]
    add_column :salary_archives, :accounting_confirmed, :boolean, null: false, default: false
    add_column :salary_archives, :accounting_confirmed_at, :datetime
end
