class LeadStatusChange < ApplicationRecord
  belongs_to :lead
  belongs_to :changed_by, class_name: "User", optional: true

  enum to_status: Lead.statuses if defined?(Lead) && Lead.respond_to?(:statuses)
end
