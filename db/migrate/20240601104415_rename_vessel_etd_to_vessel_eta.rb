class RenameVesselEtdToVesselEta < ActiveRecord::Migration[7.0]
  def change
    rename_column :bookings, :vessel_etd, :vessel_eta
  end
end
