class AddResultIdToDoneActions < ActiveRecord::Migration[7.0]
  def change
    add_reference :done_actions, :result, null: false, foreign_key: true
  end
end
