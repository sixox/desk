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


  enum role: {
    admin: 'admin',
    accounting: 'accounting',
    marketing: 'marketing',
    trading: 'trading',
    ceo: 'ceo',
    hr: 'hr',
    procurement: 'procurement'
  }


  PROFILE_TITLE = [
    'Accounting',
    'Marketing Manger',
    'Marketing',
    'Accountant Manager',
    'Procurement',
    'Procurement Manager',
    'Sales',
    'Sales Manager',
    'Operation',
    'Operation Manager',
    'HR',
    'CEO'
  ].freeze

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
