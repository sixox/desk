class MessageObserver < ApplicationRecord
  belongs_to :message
  belongs_to :observer, class_name: 'User'
end
