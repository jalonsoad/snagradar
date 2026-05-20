class ActivityEvent < ApplicationRecord
  belongs_to :defect
  belongs_to :organization
  belongs_to :actor, class_name: "User", optional: true

  validates :event_type, presence: true, length: { maximum: 60 }

  scope :for_defect, ->(defect) { where(defect: defect).order(:created_at) }

  # System event constructor
  def self.log!(defect:, type:, actor: nil, actor_label: nil, metadata: {})
    create!(
      defect:        defect,
      organization:  defect.organization,
      actor:         actor,
      actor_label:   actor_label || actor&.display_name || "System",
      event_type:    type,
      metadata:      metadata
    )
  end
end
