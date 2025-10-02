class CreateLeads < ActiveRecord::Migration[7.0]
  def change
    create_table :leads do |t|
      t.string  :name,     null: false
      t.string  :company
      t.string  :phone
      t.string  :email
      t.integer :status,   null: false, default: 0    # enum

      t.string  :source
      t.integer :owner_id

      # Offer (PI) basics
      t.decimal :offered_amount, precision: 12, scale: 2
      t.date    :offered_on

      # Simple activity helpers
      t.date    :last_contact_on
      t.text    :notes

      # ----- pipeline timestamps (for analytics) -----
      t.datetime :contacted_at
      t.datetime :responded_at
      t.datetime :offer_sent_at
      t.datetime :negotiation_started_at
      t.datetime :won_at
      t.datetime :lost_at

      # generic helper: when the current status last changed
      t.datetime :status_changed_at

      t.timestamps
    end

    add_index :leads, :status
    add_index :leads, :owner_id
    add_index :leads, :company
    add_index :leads, :phone
    add_index :leads, :email
  end
end
