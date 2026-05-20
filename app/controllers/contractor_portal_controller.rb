# Tokenised contractor view of a single defect — no login required.
# The contractor receives the URL by email; tampering invalidates the
# signed token. Expires in 14 days (set on Defect#contractor_token).
class ContractorPortalController < ApplicationController
  allow_unauthenticated_access
  layout "portal"

  before_action :load_defect

  def show; end

  def accept
    @defect.update!(status: :accepted, accepted_at: Time.current)
    ActivityEvent.log!(defect: @defect, type: "defect.accepted",
                       actor_label: @defect.contractor_company&.name || "Contractor")
    redirect_to contractor_portal_path(token: params[:token]), notice: "Thanks — we've notified customer care."
  end

  def reject
    @defect.update!(status: :rejected)
    ActivityEvent.log!(defect: @defect, type: "defect.rejected",
                       actor_label: @defect.contractor_company&.name || "Contractor",
                       metadata: { reason: params[:reason] })
    redirect_to contractor_portal_path(token: params[:token]), notice: "Rejection recorded."
  end

  def propose_appointment
    @defect.appointments.create!(
      organization: @defect.organization,
      scheduled_at: Time.zone.parse(params[:scheduled_at]),
      status: :proposed
    )
    @defect.update!(status: :booked) if @defect.status_accepted?
    ActivityEvent.log!(defect: @defect, type: "appointment.proposed",
                       actor_label: @defect.contractor_company&.name || "Contractor",
                       metadata: { scheduled_at: params[:scheduled_at] })
    redirect_to contractor_portal_path(token: params[:token]), notice: "Appointment proposed."
  rescue ArgumentError
    redirect_to contractor_portal_path(token: params[:token]), alert: "Please pick a valid date and time."
  end

  def complete
    @defect.update!(status: :completed, completed_at: Time.current)
    @defect.completion_photos.attach(params[:completion_photos]) if params[:completion_photos].present?
    ActivityEvent.log!(defect: @defect, type: "defect.completed",
                       actor_label: @defect.contractor_company&.name || "Contractor")
    redirect_to contractor_portal_path(token: params[:token]),
                notice: "Marked complete — the resident will get a sign-off link shortly."
  end

  private

  def load_defect
    @defect = Defect.find_signed!(params[:token], purpose: :contractor)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render plain: "This link has expired or is invalid.", status: :gone
  end
end
