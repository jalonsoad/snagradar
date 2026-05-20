class Notification < ApplicationRecord
  belongs_to :recipient,    class_name: "User"
  belongs_to :organization
  belongs_to :defect,       optional: true

  enum :status, { pending: 0, sent: 1, failed: 2, read: 3 }, prefix: true

  validates :channel,    presence: true, inclusion: { in: %w[email in_app] }
  validates :event_type, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
