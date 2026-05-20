class ContractorCompany < ApplicationRecord
  belongs_to :organization
  belongs_to :trade, optional: true
  has_many   :contractor_memberships, dependent: :destroy
  has_many   :users,    through: :contractor_memberships
  has_many   :defects,  dependent: :nullify

  validates :name,          presence: true, length: { maximum: 120 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :for, ->(org) { where(organization: org) }
end
