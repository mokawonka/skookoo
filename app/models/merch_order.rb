class MerchOrder < ApplicationRecord
  belongs_to :user
  belongs_to :highlight

  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  validates :color, presence: true
end
