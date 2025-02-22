class Customer < ApplicationRecord
  belongs_to :user
  has_many :pis
  has_many :cis, through: :pis
  has_many :projects, through: :pis

  def ci_count
    @ci_count ||= cis.count
  end

  def total_swift_count
    @total_swift_count ||= begin
      project_ids = projects.pluck(:id)
      ci_ids = cis.pluck(:id)
      Swift.where(project_id: project_ids).count + Swift.where(ci_id: ci_ids).count
    end
  end

  def total_swift
    @total_swift ||= begin
      project_ids = projects.pluck(:id)
      ci_ids = cis.pluck(:id)

      swifts_from_projects = Swift.where(project_id: project_ids)
      swifts_from_cis = Swift.where(ci_id: ci_ids)

      {
        dollar: swifts_from_projects.where(currency: 'dollar').sum(:amount) + swifts_from_cis.where(currency: 'dollar').sum(:amount),
        dirham: swifts_from_projects.where(currency: 'dirham').sum(:amount) + swifts_from_cis.where(currency: 'dirham').sum(:amount)
      }
    end
  end

  def total_invoices_dirham
    @total_invoices_dirham ||= calculate_total_dirham(sum_of_cis, 3.67)
  end

  def total_advance_swifts_dirham
    @total_advance_swifts_dirham ||= calculate_total_dirham(sum_of_swifts_with_advance, 3.67)
  end

  def total_balance_swifts_dirham
    @total_balance_swifts_dirham ||= calculate_total_dirham(sum_balance_swifts, 3.67)
  end

  def total_pending_dirham
    @total_pending_dirham ||= calculate_total_dirham(customer_remain_payments, 3.67)
  end

  def total_invoices_dirham_sent
    @total_invoices_dirham_sent ||= calculate_total_dirham(sum_of_cis(sent: true), 3.67)
  end

  def total_advance_swifts_dirham_sent
    @total_advance_swifts_dirham_sent ||= calculate_total_dirham(sum_of_swifts_with_advance, 3.67)
  end

  def total_balance_swifts_dirham_sent
    @total_balance_swifts_dirham_sent ||= calculate_total_dirham(sum_balance_swifts, 3.67)
  end

  def total_pending_dirham_sent
    @total_pending_dirham_sent ||= calculate_total_dirham(customer_remain_payments(sent: true), 3.67)
  end

  def total_invoices_dirham_unsent
    @total_invoices_dirham_unsent ||= calculate_total_dirham(sum_of_cis(sent: false), 3.67)
  end

  def total_advance_swifts_dirham_unsent
    @total_advance_swifts_dirham_unsent ||= calculate_total_dirham(sum_of_swifts_with_advance, 3.67)
  end

  def total_balance_swifts_dirham_unsent
    @total_balance_swifts_dirham_unsent ||= calculate_total_dirham(sum_balance_swifts, 3.67)
  end

  def total_pending_dirham_unsent
    @total_pending_dirham_unsent ||= calculate_total_dirham(customer_remain_payments(sent: false), 3.67)
  end

  def balance_swifts
    @balance_swifts ||= begin
      project_ids = projects.pluck(:id)
      ci_ids = cis.pluck(:id)

      swifts_from_projects = Swift.where(project_id: project_ids, advance: [nil, false])
      swifts_from_cis = Swift.where(ci_id: ci_ids)

      swifts_from_cis + swifts_from_projects
    end
  end

  def advance_swifts
    @advance_swifts ||= begin
      project_ids = projects.pluck(:id)
      Swift.where(project_id: project_ids, advance: true)
    end
  end

  def sum_balance_swifts
    @sum_balance_swifts ||= begin
      swifts = balance_swifts
      {
        dollar: swifts.select { |s| s.currency == 'dollar' }.sum(&:amount),
        dirham: swifts.select { |s| s.currency == 'dirham' }.sum(&:amount)
      }
    end
  end

  def sum_of_swifts_with_advance
    @sum_of_swifts_with_advance ||= begin
      swifts = advance_swifts
      {
        dollar: swifts.select { |s| s.currency == 'dollar' }.sum(&:amount),
        dirham: swifts.select { |s| s.currency == 'dirham' }.sum(&:amount)
      }
    end
  end

  def sum_of_cis(sent: nil)
    query = pis.includes(:cis).where.not(cis: { id: nil })
    
    if sent == false
      query = query.joins(:cis).where(cis: { sent: [false, nil] })
    elsif !sent.nil?
      query = query.joins(:cis).where(cis: { sent: sent })
    end

    {
      dollar: query.where(currency: 'dollar').flat_map { |pi| pi.cis.map(&:balance_payment) }.compact.sum,
      dirham: query.where(currency: 'dirham').flat_map { |pi| pi.cis.map(&:balance_payment) }.compact.sum
    }
  end

  def customer_remain_payments(sent: nil)
    ci_balance_payment = sum_of_cis(sent: sent)
    swifts_without_advance = sum_balance_swifts

    {
      dollar: ci_balance_payment[:dollar] - swifts_without_advance[:dollar],
      dirham: ci_balance_payment[:dirham] - swifts_without_advance[:dirham]
    }
  end

  def all_swifts
    @all_swifts ||= begin
      project_swifts = pis.includes(project: :swifts).flat_map { |pi| pi.project&.swifts.to_a }.compact
      ci_swifts = cis.includes(:swift).flat_map(&:swift).compact

      (project_swifts + ci_swifts).sort_by(&:created_at)
    end
  end

  private

  def calculate_total_dirham(amounts, rate)
    amounts[:dirham].to_i + (amounts[:dollar].to_i * rate)
  end
end
