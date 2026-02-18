class Subscription < ApplicationRecord
  belongs_to :user

  enum :plan, { janitor: "janitor", pomologist: "pomologist" }, default: "janitor"

  enum :status, { active: 0, trialing: 1, past_due: 2, canceled: 3 }, default: :active

  def active_or_trial?
    active? || trialing?
  end
end