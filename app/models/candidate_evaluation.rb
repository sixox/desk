# app/models/candidate_evaluation.rb
class CandidateEvaluation < ApplicationRecord
  belongs_to :candidate
  belongs_to :user       # evaluator
  has_many :questions, class_name: "CandidateEvaluationQuestion", dependent: :destroy
  accepts_nested_attributes_for :questions, allow_destroy: false

  DEPARTMENTS = %w[HR CEO Accounting Other].freeze
  GRADES = %w[A+ A B C D].freeze
  ANSWER_LABELS = %w[ضعیف متوسط خوب بسیارخوب عالی].freeze

  validates :department, inclusion: { in: DEPARTMENTS }
  validates :overall_grade, inclusion: { in: GRADES }, allow_blank: true

  # Department templates (fixed)
  FIXED_QUESTIONS = {
    "HR" => [
      "وضعیت آراستگی و پوشش ظاهری",
      "تسلط بر گفتار، رفتار و احساسات",
      "نحوه بیان، سخنوری و توانایی استدلال",
      "سرعت انتقال و توانایی درک موضوع",
      "میزان علاقه مندی به کار",
      "موفقیت شخصی",
      "توان مدیریت زمان"
    ],
    "CEO" => [
      "چشم‌انداز و نگاه کلان",
      "توان تحلیل کسب‌وکار",
      "مهارت تصمیم‌گیری",
      "توان تعامل و اقناع",
      "حل مسئله و خلاقیت"
    ],
    "Accounting" => [
      "دقت و توجه به جزئیات",
      "تسلط بر استانداردها و قوانین مالی",
      "مهارت نرم‌افزارهای مالی",
      "زمان‌بندی و تحویل به‌موقع",
      "امانت‌داری و محرمانگی",
      "تحلیل هزینه و گزارش‌دهی"
    ]
    # "Other" => no fixed
  }.freeze

  # how many custom slots per department
  CUSTOM_SLOTS = {
    "HR" => 3,
    "CEO" => 3,
    "Accounting" => 3,
    "Other" => 8
  }.freeze

  # Build/ensure the correct question set for department
  def prepare_questions!
    existing = questions.index_by(&:position)

    pos = 1
    # fixed first (if any)
    (FIXED_QUESTIONS[department] || []).each do |label|
      q = existing[pos] || questions.build(position: pos)
      q.text   = label if q.text.blank?
      q.fixed  = true
      q.weight = (q.weight.presence || 2)
      pos += 1
    end

    # then custom slots
    custom_count = CUSTOM_SLOTS[department]
    custom_count.times do
      q = existing[pos] || questions.build(position: pos)
      q.fixed  = false
      q.weight = (q.weight.presence || 2)
      # q.text stays blank for user to fill
      pos += 1
    end

    # Remove any extra questions beyond spec
    questions.where("position >= ?", pos).destroy_all

    self
  end

  # scoring
  def taken_score
    questions.sum { |q| q.score.to_i * q.weight.to_i }
  end

  def max_score
    questions
      .select { |q| q.fixed? || q.score.present? || q.text.present? }
      .sum    { |q| q.weight.to_i * 5 }
  end
end
