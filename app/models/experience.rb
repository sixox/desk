# app/models/experience.rb
class Experience < ApplicationRecord
  belongs_to :user
  has_rich_text :body
  has_many_attached :images
  has_many_attached :files
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :experience_visits, dependent: :destroy
  has_many :visitors, through: :experience_visits, source: :user


  validates :subject, presence: true
  validates :body, presence: true

  validate :validate_images

  def visits_count
    visitors.count
  end

  private

  def validate_images
    return unless images.attached?

    # Limit how many images can be attached
    if images.attachments.size > 10
      errors.add(:images, "maximum is 10 images")
    end

    images.each do |image|
      if image.blob.byte_size > 5.megabytes
        errors.add(:images, "each image must be 5MB or smaller")
      end

      unless image.blob.content_type.in?(%w[image/png image/jpeg image/jpg image/webp image/gif])
        errors.add(:images, "must be PNG, JPG, WEBP, or GIF")
      end
    end
  end
end
