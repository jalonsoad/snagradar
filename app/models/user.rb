class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  belongs_to :organization, optional: true   # internal users belong to an org; contractor users belong via membership
  has_many   :contractor_memberships, dependent: :destroy
  has_many   :contractor_companies, through: :contractor_memberships
  has_many   :reported_defects, class_name: "Defect", foreign_key: :reporter_id, dependent: :nullify
  has_many   :comments,    dependent: :destroy
  has_many   :activity_events, foreign_key: :actor_id, dependent: :nullify
  has_many   :notifications, foreign_key: :recipient_id, dependent: :destroy

  enum :role, {
    member:        0,
    care_coord:    1,    # customer-care coordinator
    site_manager:  2,
    defects_lead:  3,
    admin:         9
  }, prefix: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, length: { maximum: 80 }, allow_blank: true

  def display_name
    name.presence || email_address.split("@").first.titleize
  end

  def initials
    parts = display_name.split.first(2)
    parts.map { _1[0] }.join.upcase
  end

  def contractor?
    contractor_memberships.exists?
  end
end
