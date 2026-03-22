class Repost < ApplicationRecord
  belongs_to :user
  belongs_to :highlight
  validates :user_id, uniqueness: { scope: :highlight_id }
end