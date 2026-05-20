class Appointment < ApplicationRecord
  belongs_to :defect
  belongs_to :organization

  enum :status, { proposed: 0, confirmed: 1, attended: 2, missed: 3, cancelled: 9 }, prefix: true

  validates :scheduled_at, presence: true
  validate  :ends_after_start

  scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }

  private

  def ends_after_start
    return if ends_at.blank? || scheduled_at.blank?
    errors.add(:ends_at, "must be after the start time") if ends_at <= scheduled_at
  end
end
