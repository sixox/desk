class AddRemainVacationToSalaryArchive < ActiveRecord::Migration[7.0]
  def change
    add_column :salary_archives, :remain_vacation, :float
  end
end
