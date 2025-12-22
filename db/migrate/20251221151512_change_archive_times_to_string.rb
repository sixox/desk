class ChangeArchiveTimesToString < ActiveRecord::Migration[7.0]
  def change
    change_column :salary_archive_days, :first_in_at, :string
    change_column :salary_archive_days, :last_out_at, :string
  end
end
