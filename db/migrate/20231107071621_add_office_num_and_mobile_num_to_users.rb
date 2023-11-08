class AddOfficeNumAndMobileNumToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :office_num, :string
    add_column :users, :mobile_num, :string
  end
end
