# app/models/candidate_profile.rb
class CandidateProfile < ApplicationRecord
  belongs_to :candidate
  # data is a JSON column (Hash). We’ll store sections under keys like "s1", "s2", ...
  validates :candidate_id, presence: true
end
