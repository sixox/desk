class Booking < ApplicationRecord
  belongs_to :project

  LINE = ['HDS', 'hoopad']
  FORWARDER = ['Daryabar', 'iishipment']
  CONTAINER_TYPE = ['20-foot', '40-foot']
end
