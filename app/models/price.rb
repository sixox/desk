class Price < ApplicationRecord
  belongs_to :user
  has_many :historical_prices, dependent: :destroy

  validates :name, uniqueness: { scope: :packing, message: "and packing combination must be unique" }


  STATUSES = ['Available', 'PI Based', 'Aprox Price']

  PRODUCT = ['BITUMEN 40/50',
    'BITUMEN 60/70',
    'BITUMEN 80/100',
    'BITUMEN VG30',
    'BITUMEN VG40',
    'BITUMEN MC30',
    'BITUMEN MC3000',
    'BITUMEN 40/50 JEY EMBOSSED',
    'BITUMEN 60/70 JEY EMBOSSED',
    'BITUMEN 80/100 JEY EMBOSSED',
    'BITUMEN VG30 JEY EMBOSSED',
    'BITUMEN VG40 JEY EMBOSSED',
    'BITUMEN 40/50 PASARGAD EMBOSSED',
    'BITUMEN 60/70 PASARGAD EMBOSSED',
    'BITUMEN 80/100 PASARGAD EMBOSSED',
    'BITUMEN VG30 PASARGAD EMBOSSED',
    'BITUMEN VG40 PASARGAD EMBOSSED' 
  ]

  PACKING = ['DRUMS',
    'SECOND HAND DRUMS',
    'JUMBO',
    'FLEXI',
    '150KG DRUMS',
    'BULK'
  ]

  def self.ransackable_attributes(auth_object = nil)
    ['name', 'refinery']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end


end
