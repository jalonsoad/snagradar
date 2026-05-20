class Site < ApplicationRecord
  belongs_to :organization
  has_many   :plots,   dependent: :destroy
  has_many   :defects, dependent: :nullify
  has_many   :sla_policies, dependent: :destroy

  enum :status, { active: 0, completed: 1, archived: 9 }, prefix: true

  validates :name,      presence: true, length: { maximum: 120 }
  validates :name,      uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :reference, length: { maximum: 80 }, allow_blank: true

  scope :for, ->(org) { where(organization: org) }
end
