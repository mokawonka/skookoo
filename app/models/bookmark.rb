class Bookmark < ApplicationRecord
  belongs_to :document

  validates :cfi, presence: true
  validates :percentage, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :label, presence: true
end