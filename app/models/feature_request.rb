class FeatureRequest < ApplicationRecord
  belongs_to :user, optional: true

  enum status: { pending: 0, planned: 1, in_progress: 2, completed: 3, rejected: 4 }, _default: :pending

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
end