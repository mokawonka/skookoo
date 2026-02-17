class Subscription < ApplicationRecord
  belongs_to :user
  enum plan: { janitor: 'janitor', pomologist: 'pomologist' }, _default: 'janitor'
  enum status: { active: 0, trialing: 1, past_due: 2, canceled: 3 }, _default: :active

  def active?
    ['active', 'trialing'].include?(status)
  end
end