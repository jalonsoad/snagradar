class Defect < ApplicationRecord
  belongs_to :organization
  belongs_to :site
  belongs_to :plot,               optional: true
  belongs_to :trade
  belongs_to :contractor_company, optional: true
  belongs_to :reporter,           class_name: "User", optional: true

  has_many   :comments,        dependent: :destroy
  has_many   :appointments,    dependent: :destroy
  has_many   :activity_events, dependent: :destroy
  has_one    :sign_off,        dependent: :destroy
  has_many_attached :photos
  has_many_attached :completion_photos

  # Real-time updates over Solid Cable
  after_create_commit  -> { broadcast_dashboard_refresh }
  after_update_commit  -> { broadcast_dashboard_refresh }
  after_destroy_commit -> { broadcast_dashboard_refresh }

  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }, prefix: true
  enum :status, {
    logged:     0,
    assigned:   1,
    accepted:   2,
    booked:     3,
    in_progress: 4,
    completed:  5,
    signed_off: 6,
    closed:     7,
    rejected:   8
  }, prefix: true

  validates :title,    presence: true, length: { maximum: 200 }
  validates :priority, presence: true
  validates :status,   presence: true

  scope :for,      ->(org) { where(organization: org) }
  scope :open,     -> { where(status: %i[logged assigned accepted booked in_progress completed]) }
  scope :overdue,  -> { open.where("sla_target_date < ?", Date.current) }
  scope :amber,    ->(hours = 48) {
    open.where("sla_target_date BETWEEN ? AND ?", Date.current, hours.hours.from_now.to_date)
  }
  scope :signed_off_or_closed, -> { where(status: %i[signed_off closed]) }
  scope :recent,   -> { order(updated_at: :desc) }

  def sla_state
    return :unknown unless sla_target_date
    today = Date.current
    return :red   if sla_target_date < today
    return :amber if sla_target_date <= 2.days.from_now.to_date
    :green
  end

  def days_until_sla
    return nil unless sla_target_date
    (sla_target_date - Date.current).to_i
  end

  def open?
    %w[logged assigned accepted booked in_progress completed].include?(status)
  end

  def overdue?
    sla_target_date.present? && sla_target_date < Date.current && open?
  end

  # 14-day signed token that lets a contractor act on the defect via
  # /contractor_portal/defects/:token without logging in.
  def contractor_token
    signed_id(expires_in: 14.days, purpose: :contractor)
  end

  # 21-day signed token for the resident sign-off magic link.
  def resident_signoff_token
    signed_id(expires_in: 21.days, purpose: :resident_signoff)
  end

  private

  def broadcast_dashboard_refresh
    return if organization_id.blank?
    Turbo::StreamsChannel.broadcast_replace_to(
      [ :org, organization_id, :dashboard ],
      target:  "dashboard_counts",
      partial: "dashboards/counts",
      locals:  { counts: dashboard_counts }
    )
  rescue StandardError
    # never block a write because the stream is down
  end

  def dashboard_counts
    {
      open:       organization.defects.open.count,
      overdue:    organization.defects.overdue.count,
      amber:      organization.defects.amber.count,
      signed_off: organization.defects.signed_off_or_closed.count
    }
  end
end
