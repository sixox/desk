class ChangeKpiValueNullConstraint < ActiveRecord::Migration[7.0]
  def change
    change_column_null :kpis, :value, true
  end
end
