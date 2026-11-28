class Swift < ApplicationRecord
  before_save :set_project_number

  belongs_to :bank
  belongs_to :ci, optional: true
  belongs_to :project, optional: true
  belongs_to :car_project, class_name: 'CarImportRecord', optional: true,
             inverse_of: :project_swifts
  has_many :transactions, as: :transactionable
  has_many_attached :documents

  validates :currency, presence: true
  validates :amount, presence: true
  validate :documents_present
  validate :valid_car_project

  scope :with_bank_and_ci, -> { includes(:bank, :ci, :project, :car_project) }
  scope :visible_to, ->(user) { user.car_access? ? all : where(car_project_id: nil) }

  def self.ransackable_attributes(auth_object = nil)
    super + %w[amount from project_number]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.car_creation_allowed?(user)
    user.car_access? && (user.sales? || user.admin?)
  end

  def visible_to?(user)
    car_project_id.nil? || user.car_access?
  end

  def pending?
    !confirmed? && !rejected?
  end

  def editable_by?(user)
    visible_to?(user) && pending? && (user.sales? || user.admin?)
  end

  def confirmable_by?(user)
    visible_to?(user) && pending? && (user.accounting? || user.admin?)
  end

  def set_project_number
    self.project_number = car_project&.external_key || ci&.project&.number || project&.number
  end

  private

  def valid_car_project
    if persisted? && will_save_change_to_car_project_id? && attribute_in_database('car_project_id').present?
      errors.add(:car_project, 'cannot be changed after assignment')
    end
    return if car_project_id.blank?
    errors.add(:car_project, 'must be a car project') unless car_project&.dataset == 'CarProjects'
    if will_save_change_to_car_project_id? && !car_project&.active?
      errors.add(:car_project, 'must be active')
    end
    errors.add(:car_project, 'cannot be combined with a project or CI') if project_id.present? || ci_id.present?
  end

  def documents_present
    errors.add(:documents, 'must be attached') unless documents.attached?
  end
end
