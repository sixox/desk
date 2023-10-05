class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable



  has_many :payment_orders


  PROFILE_TITLE = [
    'Accountant',
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
