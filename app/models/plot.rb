class Plot < ApplicationRecord
  belongs_to :organization
  belongs_to :site
  has_many   :defects, dependent: :nullify

  validates :plot_number, presence: true, length: { maximum: 32 }
  validates :plot_number, uniqueness: { scope: :site_id, case_sensitive: false }

  scope :for, ->(org) { where(organization: org) }

  def label
    "Plot #{plot_number}"
  end
end
