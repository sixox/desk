class RenameWhereToLocationInMissions < ActiveRecord::Migration[7.0]
  def change
        rename_column :missions, :where, :location

  end
end
