class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by,    class_name: "User"
  belongs_to :accepted_user, class_name: "User", optional: true

  enum :role, User.roles, prefix: :role

  before_validation :assign_token, on: :create
  before_validation :set_expiry,   on: :create
  normalizes :email_address, with: ->(e) { e.to_s.strip.downcase }

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest,  presence: true, uniqueness: true
  validates :expires_at,    presence: true
  validates :email_address, uniqueness: { scope: :organization_id, conditions: -> { where(accepted_at: nil) },
                                          message: "has already been invited" }

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(accepted_at: nil).where("expires_at <= ?", Time.current) }

  attr_accessor :token  # only available right after generation (so we can email it)

  def accepted?
    accepted_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def self.find_by_token!(plain_token)
    invitation = find_by(token_digest: Digest::SHA256.hexdigest(plain_token.to_s))
    raise ActiveRecord::RecordNotFound if invitation.nil? || invitation.expired? || invitation.accepted?
    invitation
  end

  private

  def assign_token
    return if token_digest.present?
    self.token        = SecureRandom.urlsafe_base64(32)
    self.token_digest = Digest::SHA256.hexdigest(token)
  end

  def set_expiry
    self.expires_at ||= 14.days.from_now
  end
end
