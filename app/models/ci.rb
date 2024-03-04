class Ci < ApplicationRecord
  belongs_to :pi
  belongs_to :project
  belongs_to :user
  has_one :swift
  has_one :generated_document
  has_one_attached :document
  belongs_to :account, optional: true


end
