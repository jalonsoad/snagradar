class TestpageMessage < ApplicationRecord
  KINDS = %w[info success warning danger].freeze

  validates :body, presence: true, length: { maximum: 280 }
  validates :kind, inclusion: { in: KINDS }

  scope :recent, -> { order(created_at: :desc) }

  STREAM = "testpage_messages".freeze

  after_create_commit  -> { broadcast_prepend_to STREAM, target: "testpage_message_list", partial: "testpage_messages/testpage_message", locals: { testpage_message: self } }
  after_destroy_commit -> { broadcast_remove_to STREAM }
end
