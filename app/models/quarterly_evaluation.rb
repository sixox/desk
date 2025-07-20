class QuarterlyEvaluation < ApplicationRecord

  attr_accessor :review_mode

  belongs_to :user
  belongs_to :kpi_list

  has_many :done_actions, inverse_of: :quarterly_evaluation
  has_many :undone_actions, dependent: :destroy

  accepts_nested_attributes_for :done_actions, allow_destroy: true
  accepts_nested_attributes_for :undone_actions, allow_destroy: true

  validates :year, presence: true
  validates :period, presence: true, inclusion: { in: 1..4 }

  has_many_attached :files

  validate :at_least_one_action_per_result


  def review_mode=(value)
    @review_mode = ActiveModel::Type::Boolean.new.cast(value)
  end

  def review_mode
    @review_mode
  end


  def total_done_score
    done_actions
      .select { |a| a.weight.present? && a.point.present? }
      .sum { |a| a.weight.to_i * a.point.to_i }
  end

  def max_possible_done_score
    done_actions
      .select { |a| a.weight.present? }
      .sum { |a| a.weight.to_i * 10 }
  end


  def reviewed?
    done_actions
      .select { |a| a.weight.present? }
      .all? { |a| a.point.present? }
  end


  private

  # ✅ Define the method inside the class
  def at_least_one_action_per_result
    result_ids = (done_actions.map(&:result_id) + undone_actions.map(&:result_id)).uniq.compact

    kpi_results = kpi_list.targets.flat_map(&:results)

    kpi_results.each do |result|
      has_done = done_actions.any? { |a| a.result_id == result.id && a.description.present? }
      has_undone = undone_actions.any? { |a| a.result_id == result.id && a.description.present? }

      unless has_done || has_undone
        errors.add(:base, "You must fill either a done or undone action for result: #{result.description}")
      end
    end
  end

end
