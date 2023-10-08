class AddProjectToPis < ActiveRecord::Migration[7.0]
  def change
    add_reference :pis, :project, foreign_key: true
  end
end
