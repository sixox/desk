class Document < ApplicationRecord

	DOCUMENTS_TYPES = [
		'Forms',
		'Documents',
		'Announce',
	]

	has_many_attached :documents

	validates :name, presence: true
	validates :title, presence: true


end
