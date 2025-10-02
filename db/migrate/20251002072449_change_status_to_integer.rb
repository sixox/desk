class ChangeStatusToInteger < ActiveRecord::Migration[7.0]
  def up
    # If the column already exists as integer, do nothing
    return if column_exists?(:lead_status_changes, :to_status, :integer)

    # Add a new integer column temporarily
    add_column :lead_status_changes, :to_status_int, :integer

    # Map strings -> integers per Lead.statuses
    # If your Lead enum is:
    # { new_lead: 0, contacted: 1, responded: 2, offer_sent: 3, negotiation: 4, won: 5, lost: 6 }
    execute <<~SQL
    UPDATE lead_status_changes SET to_status_int =
    CASE to_status
    WHEN 'new_lead'   THEN 0
    WHEN 'contacted'  THEN 1
    WHEN 'responded'  THEN 2
    WHEN 'offer_sent' THEN 3
    WHEN 'negotiation'THEN 4
    WHEN 'won'        THEN 5
    WHEN 'lost'       THEN 6
    ELSE NULL
    END
    SQL

    # Drop old string col and rename
    remove_column :lead_status_changes, :to_status
    rename_column  :lead_status_changes, :to_status_int, :to_status

    # Add an index if you like
    add_index :lead_status_changes, :to_status
  end

  def down
    # reverse (integer -> string)
    add_column :lead_status_changes, :to_status_str, :string

    execute <<~SQL
    UPDATE lead_status_changes SET to_status_str =
    CASE to_status
    WHEN 0 THEN 'new_lead'
    WHEN 1 THEN 'contacted'
    WHEN 2 THEN 'responded'
    WHEN 3 THEN 'offer_sent'
    WHEN 4 THEN 'negotiation'
    WHEN 5 THEN 'won'
    WHEN 6 THEN 'lost'
    ELSE NULL
    END
    SQL

    remove_column :lead_status_changes, :to_status
    rename_column  :lead_status_changes, :to_status_str, :to_status
  end
end
