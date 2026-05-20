class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  INTERESTS = %w[demo pilot sales].freeze

  attribute :name,            :string
  attribute :company,         :string
  attribute :email,           :string
  attribute :phone,           :string
  attribute :interest,        :string, default: "demo"
  attribute :message,         :string
  attribute :terms_accepted,  :boolean, default: false

  validates :name,           presence: true, length: { maximum: 80 }
  validates :company,        presence: true, length: { maximum: 80 }
  validates :email,          presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "doesn't look right" }
  validates :interest,       inclusion: { in: INTERESTS, message: "is required" }
  validates :message,        presence: true, length: { minimum: 10, maximum: 2000, too_short: "needs at least 10 characters" }
  validates :terms_accepted, acceptance: { message: "must be accepted" }
end
