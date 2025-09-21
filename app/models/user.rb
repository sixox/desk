class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable, :trackable



  has_many :payment_orders
  has_many :vacations
  has_many :customers
  has_many :pis
  has_many :cis
  has_many :spis
  has_many :suppliers
  has_many :scis
  has_many :notifications
  has_many :comments
  has_many :clients
  has_many :reports
  has_many :prices
  has_many :historical_prices, dependent: :destroy
  has_many :generated_documents

  has_many :sent_messages, class_name: 'Message', foreign_key: :sender_id
  has_many :received_messages, class_name: 'Message', foreign_key: :receiver_id
  has_many :message_observers, foreign_key: :observer_id
  has_many :observed_messages, through: :message_observers, source: :message
  has_many :acts

    # This association represents the forms that are about the user
  has_many :assessment_forms_as_user, class_name: 'AssessmentForm', foreign_key: 'user_id', dependent: :destroy

  # This association represents the forms the user is filling out (filler role)
  has_many :assessment_forms_as_filler, class_name: 'AssessmentForm', foreign_key: 'filler_id', dependent: :destroy
  has_many :satisfaction_forms, dependent: :destroy
  has_many :satisfactions, through: :satisfaction_forms

  has_many :message_tags, dependent: :destroy
  has_many :tagged_messages, through: :message_tags, source: :message
  has_many :kpi_lists, dependent: :destroy

  has_many :stakeholder_survey_forms, dependent: :destroy
  has_many :quarterly_evaluations, dependent: :destroy

  has_many :experiences
  has_many :experience_visits, dependent: :destroy
  has_many :visited_experiences, through: :experience_visits, source: :experience





  has_one_attached :signature






  enum role: {
    admin: 'admin',
    accounting: 'accounting',
    marketing: 'marketing',
    sales: 'sales',
    ceo: 'ceo',
    hr: 'hr',
    procurement: 'procurement',
    exchange: 'exchange',
    board: 'board',
    cob: 'cob' ,
    logistics: 'logistics'   
  }


  PROFILE_TITLE = [
    'Accounting',
    'Marketing Manger',
    'Marketing',
    'Accountant Manager',
    'procurement',
    'Procurement Manager',
    'Sales',
    'Sales Manager',
    'Operation',
    'Operation Manager',
    'HR',
    'CEO',
    'general',
    'sales',
    'masoud',
    'logestic',
    'exchange'
  ].freeze

  FOUNDERS = [
    { id: 7, name: 'سهیل جمشیدی' },
    { id: 3, name: 'صفار محمدی' }
  ].freeze

  scope :managers_for_role, ->(role) { where(role: role, is_manager: true) }



  def name
    "#{first_name} #{last_name}".strip
  end
  def self.ransackable_attributes(auth_object = nil)
    ['first_name', 'last_name']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end


end
