class Addfewtosome < ActiveRecord::Migration[7.0]
  def change
    # 4 items for accounting adjustments (2 additions, 2 deductions)
    add_column :salary_archives, :acc_add_1_title, :string
    add_column :salary_archives, :acc_add_1_amount, :integer, default: 0, null: false
    add_column :salary_archives, :acc_add_2_title, :string
    add_column :salary_archives, :acc_add_2_amount, :integer, default: 0, null: false

    add_column :salary_archives, :acc_ded_1_title, :string
    add_column :salary_archives, :acc_ded_1_amount, :integer, default: 0, null: false
    add_column :salary_archives, :acc_ded_2_title, :string
    add_column :salary_archives, :acc_ded_2_amount, :integer, default: 0, null: false

    # store supplementary insurance INSIDE archive too (important for historical payslips)
    add_column :salary_archives, :supplementary_insurance, :integer, default: 0, null: false

    # add to profile: bime takmili (deduction)
    add_column :salary_profiles, :supplementary_insurance, :integer, default: 0, null: false
  end
end
