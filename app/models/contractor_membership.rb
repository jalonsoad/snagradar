class ContractorMembership < ApplicationRecord
  belongs_to :user
  belongs_to :contractor_company

  enum :role, { member: 0, owner: 1 }, prefix: true

  validates :user_id, uniqueness: { scope: :contractor_company_id }
end
