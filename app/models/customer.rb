class Customer < ApplicationRecord
  belongs_to :user
  has_many :pis

  def total_swift_amount
    project_ids = self.pis.map { |pi| pi.project_id }.compact
    ci_ids = self.pis.flat_map { |pi| pi.cis.map(&:id) }

    swifts_from_projects = Swift.where(project_id: project_ids)
    swifts_from_cis = Swift.where(ci_id: ci_ids)

    {
      dollar: swifts_from_projects.where(currency: 'dollar').sum(:amount) + swifts_from_cis.where(currency: 'dollar').sum(:amount),
      dirham: swifts_from_projects.where(currency: 'dirham').sum(:amount) + swifts_from_cis.where(currency: 'dirham').sum(:amount)
    }
  end

  def swifts_from_cis_and_projects_without_advance
    project_ids = self.pis.map { |pi| pi.project_id }.compact
    ci_ids = self.pis.flat_map { |pi| pi.cis.map(&:id) }

    swifts_from_projects = Swift.where(project_id: project_ids, advance: [nil, false])
    swifts_from_cis = Swift.where(ci_id: ci_ids)

    swifts_from_cis + swifts_from_projects
  end

  def swifts_from_projects_with_advance
    project_ids = self.pis.map { |pi| pi.project_id }.compact

    Swift.where(project_id: project_ids, advance: true)
  end

  def sum_of_swifts_without_advance
    swifts = swifts_from_cis_and_projects_without_advance
    {
      dollar: swifts.select { |s| s.currency == 'dollar' }.sum(&:amount),
      dirham: swifts.select { |s| s.currency == 'dirham' }.sum(&:amount)
    }
  end

  def sum_of_swifts_with_advance
    swifts = swifts_from_projects_with_advance
    {
      dollar: swifts.select { |s| s.currency == 'dollar' }.sum(&:amount),
      dirham: swifts.select { |s| s.currency == 'dirham' }.sum(&:amount)
    }
  end

  def sum_of_ci_balance_payment
    pis_with_currency = self.pis.includes(:cis).where.not(cis: { id: nil })

    {
      dollar: pis_with_currency.where(currency: 'dollar').flat_map { |pi| pi.cis.map(&:balance_payment) }.sum,
      dirham: pis_with_currency.where(currency: 'dirham').flat_map { |pi| pi.cis.map(&:balance_payment) }.sum
    }
  end

  def ci_balance_payment_minus_sum_of_swifts_without_advance
    ci_balance_payment = sum_of_ci_balance_payment
    swifts_without_advance = sum_of_swifts_without_advance

    {
      dollar: ci_balance_payment[:dollar] - swifts_without_advance[:dollar],
      dirham: ci_balance_payment[:dirham] - swifts_without_advance[:dirham]
    }
  end
end
