class Candidate < ApplicationRecord
  has_secure_password

  validates :name, :phone, :role, :password, presence: true
  validates :phone, uniqueness: true
end
