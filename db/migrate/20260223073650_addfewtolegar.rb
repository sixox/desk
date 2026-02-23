class Addfewtolegar < ActiveRecord::Migration[7.0]
  def change
    add_column :salary_archives, :legal_add_1_title,  :string
    add_column :salary_archives, :legal_add_1_amount, :integer, default: 0, null: false

    add_column :salary_archives, :legal_add_2_title,  :string
    add_column :salary_archives, :legal_add_2_amount, :integer, default: 0, null: false

    add_column :salary_archives, :legal_ded_1_title,  :string
    add_column :salary_archives, :legal_ded_1_amount, :integer, default: 0, null: false

    add_column :salary_archives, :legal_ded_2_title,  :string
    add_column :salary_archives, :legal_ded_2_amount, :integer, default: 0, null: false
  end
end
