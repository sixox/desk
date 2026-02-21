class SalaryArchive < ApplicationRecord
  belongs_to :user
  belongs_to :shamsi_month

  belongs_to :manager_confirmed_by, class_name: "User", optional: true

  has_many :days, class_name: "SalaryArchiveDay", dependent: :destroy

  enum status: { draft: 0, manager_confirmed: 1 }

  validates :user_id, uniqueness: { scope: :shamsi_month_id }

  def total_overtime_minutes_final
    (overtime_minutes.to_i + manual_overtime_minutes.to_i)
  end

  def total_deficit_minutes_final
    (deficit_minutes.to_i + manual_deficit_minutes.to_i)
  end

  def confirmed?
    manager_confirmed_at.present?
  end

  # -----------------------------
  # ✅ NEW: Accounting adjustments totals
  # -----------------------------
  def accounting_additions_total
    acc_add_1_amount.to_i + acc_add_2_amount.to_i
  end

  def accounting_deductions_total
    acc_ded_1_amount.to_i + acc_ded_2_amount.to_i + supplementary_insurance.to_i
  end

  # convenience for showing items (avoid empty titles)
  def accounting_addition_items
    items = []
    if acc_add_1_amount.to_i != 0 || acc_add_1_title.to_s.strip.present?
      items << [acc_add_1_title.to_s.strip, acc_add_1_amount.to_i]
    end
    if acc_add_2_amount.to_i != 0 || acc_add_2_title.to_s.strip.present?
      items << [acc_add_2_title.to_s.strip, acc_add_2_amount.to_i]
    end
    items
  end

  def accounting_deduction_items
    items = []
    if acc_ded_1_amount.to_i != 0 || acc_ded_1_title.to_s.strip.present?
      items << [acc_ded_1_title.to_s.strip, acc_ded_1_amount.to_i]
    end
    if acc_ded_2_amount.to_i != 0 || acc_ded_2_title.to_s.strip.present?
      items << [acc_ded_2_title.to_s.strip, acc_ded_2_amount.to_i]
    end
    # profile-based, stored in archive at accounting confirm
    if supplementary_insurance.to_i > 0
      items << ["بیمه تکمیلی", supplementary_insurance.to_i]
    end
    items
  end

  def recalculate_totals!
    self.total_work_minutes = days.sum(:work_minutes)
    self.overtime_minutes   = days.sum(:overtime_minutes)
    self.deficit_minutes    = days.sum(:deficit_minutes)
    save!
  end
end