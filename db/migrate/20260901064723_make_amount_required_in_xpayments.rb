class MakeAmountRequiredInXpayments < ActiveRecord::Migration[7.0]
  def up
    rename_column :xpayments, :amount, :sent_amount

    add_column :xpayments, :received_amount, :bigint

    execute <<~SQL
      UPDATE xpayments
      SET received_amount = sent_amount
    SQL

    change_column_null :xpayments, :sent_amount, false
    change_column_null :xpayments, :received_amount, false
  end

  def down
    change_column_null :xpayments, :sent_amount, true
    change_column_null :xpayments, :received_amount, true

    remove_column :xpayments, :received_amount

    rename_column :xpayments, :sent_amount, :amount
  end
end