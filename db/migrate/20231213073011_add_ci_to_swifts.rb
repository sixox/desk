class AddCiToSwifts < ActiveRecord::Migration[7.0]
  def change
    add_reference :swifts, :ci, null: false, foreign_key: true
  end
end
