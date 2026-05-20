class Trade < ApplicationRecord
  belongs_to :organization
  has_many   :defects,             dependent: :nullify
  has_many   :contractor_companies, dependent: :nullify
  has_many   :sla_policies,        dependent: :destroy

  validates :name,             presence: true, length: { maximum: 60 }
  validates :name,             uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :default_sla_days, presence: true, numericality: { only_integer: true, in: 1..90 }

  scope :for, ->(org) { where(organization: org) }
end
