class Removesoefromfew < ActiveRecord::Migration[7.0]
  def up
    # Remove from organizations
    remove_column :organizations, :start_amount, :bigint
    remove_column :organizations, :date_change_start_amount, :date
    remove_column :organizations, :details_of_change_start_amount, :text

    # Add to xaccounts
    add_column :xaccounts, :start_amount, :bigint
    add_column :xaccounts, :date_change_start_amount, :date
    add_column :xaccounts, :details_of_change_start_amount, :text
  end

  def down
    # Remove from xaccounts
    remove_column :xaccounts, :start_amount, :bigint
    remove_column :xaccounts, :date_change_start_amount, :date
    remove_column :xaccounts, :details_of_change_start_amount, :text

    # Add back to organizations
    add_column :organizations, :start_amount, :bigint
    add_column :organizations, :date_change_start_amount, :date
    add_column :organizations, :details_of_change_start_amount, :text
  end
end



