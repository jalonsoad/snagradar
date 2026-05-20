class Organization < ApplicationRecord
  has_many :users,                dependent: :nullify
  has_many :sites,                dependent: :destroy
  has_many :plots,                dependent: :destroy
  has_many :trades,               dependent: :destroy
  has_many :contractor_companies, dependent: :destroy
  has_many :defects,              dependent: :destroy
  has_many :appointments,         dependent: :destroy
  has_many :activity_events,      dependent: :destroy
  has_many :notifications,        dependent: :destroy
  has_many :sla_policies,         dependent: :destroy

  enum :status, { active: 0, suspended: 1, archived: 9 }, prefix: true

  normalizes :name, with: ->(v) { v.strip }

  validates :name, presence: true, length: { maximum: 80 }
  validates :slug, presence: true, length: { maximum: 60 }, uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "may only contain lowercase letters, numbers and dashes" }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    return if slug.present?
    base = name.to_s.parameterize
    self.slug = base.presence || SecureRandom.hex(4)
  end
end
