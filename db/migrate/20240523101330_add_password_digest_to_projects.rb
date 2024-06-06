class AddPasswordDigestToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :password_digest, :string
  end
end
