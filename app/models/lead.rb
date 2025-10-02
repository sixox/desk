class Lead < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :status_changes, class_name: "LeadStatusChange", dependent: :destroy
  has_many :lead_tasks, dependent: :destroy



  enum status: {
    new_lead:       0,
    contacted:      1,
    responded:      2,
    offer_sent:     3,
    negotiation:    4,
    won:            5,
    lost:           6
  }

  validates :name, presence: true
  validates :status, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }

  # ===== Status timestamping =====
  before_save :stamp_status_transition, if: :will_save_change_to_status?

  def stamp_status_transition
    self.status_changed_at = Time.current

    case status
    when "contacted"
      self.contacted_at ||= Time.current
    when "responded"
      self.responded_at ||= Time.current
    when "offer_sent"
      self.offer_sent_at ||= Time.current
      # convenience: if user forgot the date, set it to today
      self.offered_on ||= Date.current
    when "negotiation"
      self.negotiation_started_at ||= Time.current
    when "won"
      self.won_at ||= Time.current
    when "lost"
      self.lost_at ||= Time.current
    end
  end

  # ===== Pretty badge for status =====
  # helper to colorize badges you already used
  def badge_class
    {
      "new"          => "secondary",
      "contacted"    => "info",
      "qualified"    => "primary",
      "offer_sent"   => "warning",
      "won"          => "success",
      "lost"         => "danger"
    }[status] || "secondary"
  end

  # ===== Durations for dashboard (all return seconds or nil) =====
  def time_to_first_contact
    return unless contacted_at
    contacted_at - created_at
  end

  def time_to_response
    return unless contacted_at && responded_at
    responded_at - contacted_at
  end

  def time_to_offer
    # from first meaningful interest to PI
    anchor = responded_at || contacted_at
    return unless anchor && offer_sent_at
    offer_sent_at - anchor
  end

  def decision_time_after_offer
    terminal = won_at || lost_at
    return unless offer_sent_at && terminal
    terminal - offer_sent_at
  end

  # A helper you can show: “current status age”
  def current_status_age
    return unless status_changed_at
    Time.current - status_changed_at
  end
end
