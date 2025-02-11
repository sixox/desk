class AddIndexToIssueDate < ActiveRecord::Migration[7.0]
  def change
    add_index :pis, :issue_date
    add_index :cis, :issue_date
  end
end
