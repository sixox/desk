class QuarterlyEvaluation < ApplicationRecord

  attr_accessor :review_mode

  belongs_to :user
  belongs_to :kpi_list

  has_many :done_actions, dependent: :destroy
  has_many :undone_actions, dependent: :destroy

  accepts_nested_attributes_for :done_actions, allow_destroy: true
  accepts_nested_attributes_for :undone_actions, allow_destroy: true

  validates :year, presence: true
  validates :period, presence: true, inclusion: { in: 1..4 }

  has_many_attached :files



    def review_mode=(value)
      @review_mode = ActiveModel::Type::Boolean.new.cast(value)
      done_actions.each { |a| a.review_mode = @review_mode }
      undone_actions.each { |a| a.review_mode = @review_mode }
    end

end
