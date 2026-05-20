class Comment < ApplicationRecord
  belongs_to :defect
  belongs_to :user
  belongs_to :organization

  enum :visibility, { internal: 0, external: 1 }, prefix: true

  validates :body, presence: true, length: { maximum: 4_000 }
end
