class AddDepartmentToKpiList < ActiveRecord::Migration[7.0]
  def change
    add_column :kpi_lists, :department, :string
  end
end
