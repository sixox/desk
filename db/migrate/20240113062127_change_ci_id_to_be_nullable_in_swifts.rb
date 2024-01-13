class ChangeCiIdToBeNullableInSwifts < ActiveRecord::Migration[7.0]
  def change
        change_column_null :swifts, :ci_id, true

  end
end
