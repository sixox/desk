class Customer < ApplicationRecord
  belongs_to :user
  has_many :pis
  has_many :cis, through: :pis
  has_many :projects, through: :pis

  def total_swift
    project_ids = projects.pluck(:id)
    ci_ids = cis.pluck(:id)

    swifts_from_projects = Swift.where(project_id: project_ids)
    swifts_from_cis = Swift.where(ci_id: ci_ids)

    {
      dollar: swifts_from_projects.where(currency: 'dollar').sum(:amount) + swifts_from_cis.where(currency: 'dollar').sum(:amount),
      dirham: swifts_from_projects.where(currency: 'dirham').sum(:amount) + swifts_from_cis.where(currency: 'dirham').sum(:amount)
    }
  end

  def total_swift_count
    project_ids = projects.pluck(:id)
    ci_ids = cis.pluck(:id)
    a = Swift.where(project_id: project_ids).count
    b = Swift.where(ci_id: ci_ids).count
    a + b
  end

  def balance_swifts
    project_ids = projects.pluck(:id)
    ci_ids = cis.pluck(:id)

    swifts_from_projects = Swift.where(project_id: project_ids, advance: [nil, false])
    swifts_from_cis = Swift.where(ci_id: ci_ids)

    swifts_from_cis + swifts_from_projects
  end

  def advance_swifts
    project_ids = projects.pluck(:id)
    Swift.where(project_id: project_ids, advance: true)
  end

  def sum_balance_swifts
    swifts = balance_swifts
    {
      dollar: swifts.select { |s| s.currency == 'dollar' }.sum(&:amount),
      dirham: swifts.select { |s| s.currency == 'dirham' }.sum(&:amount)
    }
  end

  def sum_of_swifts_with_advance
    swifts = advance_swifts
    {
      dollar: swifts.select { |s| s.currency == 'dollar' }.sum(&:amount),
      dirham: swifts.select { |s| s.currency == 'dirham' }.sum(&:amount)
    }
  end

  def sum_of_cis
    pis_with_currency = self.pis.includes(:cis).where.not(cis: { id: nil })
    {
      dollar: pis_with_currency.where(currency: 'dollar').flat_map { |pi| pi.cis.map(&:balance_payment) }.compact.sum,
      dirham: pis_with_currency.where(currency: 'dirham').flat_map { |pi| pi.cis.map(&:balance_payment) }.compact.sum
    }
  end

  def sum_of_cis_without_swift
    pis_with_currency = self.pis.includes(:cis).where.not(cis: { id: nil })
    {
      dollar: pis_with_currency.where(currency: 'dollar').flat_map { |pi| pi.cis.select { |ci| ci.swift.nil? }.map(&:balance_payment) }.compact.sum,
      dirham: pis_with_currency.where(currency: 'dirham').flat_map { |pi| pi.cis.select { |ci| ci.swift.nil? }.map(&:balance_payment) }.compact.sum
    }
  end

  def customer_remain_payments
    ci_balance_payment = sum_of_cis
    swifts_without_advance = sum_balance_swifts

    {
      dollar: ci_balance_payment[:dollar] - swifts_without_advance[:dollar],
      dirham: ci_balance_payment[:dirham] - swifts_without_advance[:dirham]
    }
  end
end
