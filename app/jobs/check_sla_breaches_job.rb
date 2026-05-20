# Runs nightly via Solid Queue (see config/recurring.yml).
# Walks every open defect across every org, flags amber + red defects,
# logs an ActivityEvent, and notifies care + the contractor.
class CheckSlaBreachesJob < ApplicationJob
  queue_as :default

  def perform
    today    = Date.current
    amber_at = 2.days.from_now.to_date  # default amber threshold — 48h

    Defect.open.where("sla_target_date IS NOT NULL").find_each do |defect|
      next unless defect.sla_target_date

      if defect.sla_target_date < today
        flag(defect, severity: :red,
                     subject: "Defect overdue",
                     preview: "#{defect.title} passed its SLA on #{defect.sla_target_date.strftime('%d %b')}")
      elsif defect.sla_target_date <= amber_at
        flag(defect, severity: :amber,
                     subject: "Defect approaching SLA",
                     preview: "#{defect.title} due #{defect.sla_target_date.strftime('%d %b')}")
      end
    end
  end

  private

  def flag(defect, severity:, subject:, preview:)
    # idempotent: only log once per day per defect per severity
    return if defect.activity_events
                    .where("created_at > ?", 20.hours.ago)
                    .where(event_type: "sla.#{severity}")
                    .exists?

    ActivityEvent.log!(defect: defect, type: "sla.#{severity}",
                       actor_label: "SLA monitor",
                       metadata: { sla_target_date: defect.sla_target_date.iso8601 })

    Notification.create!(
      recipient:    defect.reporter || defect.organization.users.where(role: User.roles[:admin]).first,
      organization: defect.organization,
      defect:       defect,
      channel:      "in_app",
      event_type:   "sla.#{severity}",
      subject:      "#{subject}: #{defect.title}",
      preview:      preview,
      status:       :sent,
      sent_at:      Time.current
    )
  end
end
