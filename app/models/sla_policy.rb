class SlaPolicy < ApplicationRecord
  belongs_to :organization
  belongs_to :trade, optional: true
  belongs_to :site,  optional: true

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, prefix: true

  validates :target_days,           presence: true, numericality: { only_integer: true, in: 1..90 }
  validates :amber_threshold_hours, presence: true, numericality: { only_integer: true, in: 1..(7 * 24) }
end
