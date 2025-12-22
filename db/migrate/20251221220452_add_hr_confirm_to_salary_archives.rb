class AddHrConfirmToSalaryArchives < ActiveRecord::Migration[7.0]
  def change
    add_column :salary_archives, :hr_confirmed, :boolean, null: false, default: false
    add_column :salary_archives, :hr_confirmed_at, :datetime
  end
end
