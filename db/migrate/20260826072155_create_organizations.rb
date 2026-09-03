class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :kind
      t.bigint :start_amount
      t.date :date_change_start_amount
      t.text :details_of_change_start_amount

      t.timestamps
    end
  end
end
