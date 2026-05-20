class SignOff < ApplicationRecord
  belongs_to :defect
  belongs_to :organization

  validates :signer_name,  presence: true, length: { maximum: 120 }
  validates :token_digest, presence: true
  validates :signed_at,    presence: true
  validates :signer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
