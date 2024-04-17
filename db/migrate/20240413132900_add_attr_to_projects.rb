class AddAttrToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :attr, :string
  end
end
