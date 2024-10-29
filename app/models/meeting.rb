class Meeting < ApplicationRecord
  belongs_to :secretary, class_name: 'User'
  has_many :actions, dependent: :destroy
  serialize :participants, Array  # Store participants as an array of user IDs

  validates :title, :date, :secretary, presence: true

  accepts_nested_attributes_for :actions, allow_destroy: true
end
