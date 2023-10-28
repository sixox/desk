class Pi < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  belongs_to :project
  has_many :cis

  has_one_attached :document

  PRODUCT = ['BITUMEN EMBOSSED GRADE 80/100 ',
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
             'BITUMEN PG70-10',
             'BITUMEN VG40',
             'CRYSTAL BITUMEN',
             'CUT BACK BITUMEN RC-70',
             'CUTBACK BITUMEN MC-3000',
             'CUTBACK MC30',
             'EMULSION BITUMEN CSS-60',
             'PG-7622',
             'BASE OIL',
             'ENGINE OIL',
             'ENGINE OIL SAE 40',
             'PARAFFIN WAX 1-2%',
             'PARAFFIN WAX 5-7%',
             'PARAFFIN WAX H5%',
             'PARAFFIN WAX 3-5%',
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
             'LIGHT BEHRAN',
             'HEAVY BEHRAN',
             'HEAVY PARS',
             'LIGHT PARS',
             'IRANOL-SW10-AB',
             'IRANOL-SW40',
             'IRANOL-SW10-TEH',
             'UREA',
             'UREA  46%'
           ]
  CURRENCY = ['dollar', 'dirham', 'rial']
  PAYMENT_TERM = ['30% advance', '20% advance']
  POL = ['IRAN', 'UAE', 'BND/IRAN']
  PACKING_TYPE = ['180kg new drums', 'Jumbo', '180kg second hand drums', 'bulk']
  SELLER = ['ZigguratOil', 'WhiteSands']

end
