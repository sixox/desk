class FixCreditsXaccountForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :credits, :accounts

    add_foreign_key :credits, :xaccounts, column: :xaccount_id
  end
end
