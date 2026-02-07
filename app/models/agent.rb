# frozen_string_literal: true

class Agent < ApplicationRecord
  API_KEY_PREFIX = "skookoo_"
  VERIFICATION_PREFIX = "skookoo-"
  STATUS_PENDING_CLAIM = "pending_claim"
  STATUS_CLAIMED = "claimed"

  before_validation :generate_credentials, on: :create

  validates :name, presence: true
  validates :api_key, presence: true, uniqueness: true
  validates :claim_token, presence: true, uniqueness: true
  validates :verification_code, presence: true
  validates :status, presence: true, inclusion: { in: [STATUS_PENDING_CLAIM, STATUS_CLAIMED] }

  scope :claimed, -> { where(status: STATUS_CLAIMED) }
  scope :pending_claim, -> { where(status: STATUS_PENDING_CLAIM) }

  def claimed?
    status == STATUS_CLAIMED
  end

  def pending_claim?
    status == STATUS_PENDING_CLAIM
  end

  def claim!
    update!(status: STATUS_CLAIMED)
  end

  def self.authenticate_by_api_key(key)
    return nil if key.blank?
    key = key.sub(/\ABearer\s+/i, "").strip
    find_by(api_key: key)
  end

  private

  def generate_credentials
    return if api_key.present?
    self.api_key = generate_api_key
    self.claim_token = SecureRandom.urlsafe_base64(32)
    self.verification_code = "#{VERIFICATION_PREFIX}#{SecureRandom.alphanumeric(6).downcase}"
    self.status = STATUS_PENDING_CLAIM
  end

  def generate_api_key
    loop do
      key = "#{API_KEY_PREFIX}#{SecureRandom.urlsafe_base64(24)}"
      break key unless Agent.exists?(api_key: key)
    end
  end
end
