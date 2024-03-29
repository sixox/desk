class Pi < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  belongs_to :project, optional: true
  has_many :cis, dependent: :destroy # or :nullify if you prefer not to delete them
  has_one :generated_document, dependent: :destroy
  has_one_attached :document
  belongs_to :account, optional: true


  PRODUCT = ['BASE OIL',
   'BASEOIL SN 100',
   'BASEOIL SN 150',
   'BASEOIL SN 500',
   'BASEOIL SN 600',
   'BASEOIL SN 650',
   'BITUMEN EMBOSSED GRADE 80/100 ',
   'BITUMEN EMULSION CRS-1',
   'BITUMEN EMULSION K1-60',
   'BITUMEN GRADE 40/50',
   'BITUMEN GRADE 60/70',
   'BITUMEN GRADE 60/70 JEY EMBOSSED',
   'BITUMEN GRADE 80/100',
   'BITUMEN GRADE 80/100 JEY EMBOSSED',
   'BITUMEN GRADE PG70-22',
   'BITUMEN GRADE VG30',
   'BITUMEN GRADE VG40',
   'BITUMEN GRADE VG40 JEY EMBOSSED',
   'BITUMEN MIX GRADE',
   'BITUMEN PG70-10',
   'CRYSTAL BITUMEN',
   'CUT BACK BITUMEN RC-70',
   'CUTBACK BITUMEN MC-3000',
   'CUTBACK MC30',
   'EMULSION BITUMEN CSS-60',
   'ENGINE OIL',
   'ENGINE OIL SAE 40',
   'HEAVY BEHRAN',
   'HEAVY PARS',
   'IRANOL-SW10-AB',
   'IRANOL-SW10-TEH',
   'IRANOL-SW40',
   'LIGHT BEHRAN',
   'LIGHT PARS',
   'PARAFFIN WAX 1-2%',
   'PARAFFIN WAX 3-5%',
   'PARAFFIN WAX 5-8%',
   'PARAFFIN WAX H5%',
   'PG-7622',
   'RPO 135',
   'RPO 145',
   'RPO DAE 20',
   'RPO DAE 40',
   'RPO GR-20',
   'RPO GR-40',
   'RPO HEAVY',
   'RPO10',
   'RPO30',
   'RPO40',
   'UREA',
   'UREA  46%']

   CURRENCY = ['dollar', 'dirham', 'rial', 'euro']
   PAYMENT_TERM = ['30% advance', '20% advance']
   POL = ['IRAN', 'UAE', 'BND/IRAN']
   PACKING_TYPE = ['180kg new drums', 'Jumbo', '180kg second hand drums', '150kg drums', '200kg second hand drums', 'bulk', 'cartons', 'flexi']
   SELLER = ['ZigguratOil', 'WhiteSands']

  scope :without_project, -> { 
    left_outer_joins(:project).where(projects: { id: nil }) 
  }
  scope :with_project, -> { 
    left_outer_joins(:project).where.not(projects: { id: nil }) 
  }

 end
