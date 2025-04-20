class AddTitleToKpiList < ActiveRecord::Migration[7.0]
  def change
    add_column :kpi_lists, :title, :string
  end
end
