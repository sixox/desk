class AddAnnounceToSwifts < ActiveRecord::Migration[7.0]
  def change
    add_column :swifts, :announce, :boolean
  end
end
