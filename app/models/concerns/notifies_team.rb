# Defect concern: turns state changes into Notifications + mailer triggers.
module NotifiesTeam
  extend ActiveSupport::Concern

  included do
    after_update_commit :emit_state_change_notification, if: :saved_change_to_status?
  end

  private

  def emit_state_change_notification
    case status
    when "assigned"  then notify_assignment
    when "accepted"  then notify_care_team("Defect accepted",  "#{contractor_company&.name} accepted the defect.")
    when "rejected"  then notify_care_team("Defect rejected",  "#{contractor_company&.name || 'Contractor'} rejected the defect — needs reassignment.")
    when "completed" then notify_care_team("Work completed",   "#{contractor_company&.name} marked it complete — ready for resident sign-off.")
    when "signed_off"then notify_care_team("Resident signed off","Sign-off captured — ready to close.")
    when "closed"    then notify_care_team("Defect closed",    "Defect closed.")
    end
  end

  def notify_assignment
    notify_care_team("Defect assigned",
                     "Routed to #{contractor_company&.name || 'a contractor'}.")
    return if contractor_company&.contact_email.blank?
    DefectMailer.assigned(self).deliver_later
  end

  def notify_care_team(subject, preview)
    recipients = organization.users
      .where.not(role: [User.roles[:member], User.roles[:site_manager]])
    recipients.find_each do |recipient|
      next if recipient.id == reporter_id  # don't ping the person who just acted
      recipient.notifications.create!(
        organization: organization, defect: self,
        channel: "in_app", event_type: "defect.#{status}",
        subject: "#{subject}: #{title}", preview: preview, status: :sent, sent_at: Time.current
      )
    end
  end
end
