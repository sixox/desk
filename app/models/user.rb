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

    # This association represents the forms that are about the user
  has_many :assessment_forms_as_user, class_name: 'AssessmentForm', foreign_key: 'user_id', dependent: :destroy

  # This association represents the forms the user is filling out (filler role)
  has_many :assessment_forms_as_filler, class_name: 'AssessmentForm', foreign_key: 'filler_id', dependent: :destroy
  has_many :satisfaction_forms, dependent: :destroy
  has_many :satisfactions, through: :satisfaction_forms

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
    cob: 'cob'    
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
