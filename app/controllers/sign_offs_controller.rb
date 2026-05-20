# Resident sign-off — no auth, accessed via tokenised magic link.
# Stores name, signature image (base64), IP/UA + token digest as evidence.
class SignOffsController < ApplicationController
  allow_unauthenticated_access
  layout "portal"

  before_action :load_defect

  def new
    @sign_off = @defect.build_sign_off
  end

  def create
    @sign_off = @defect.build_sign_off(
      signer_name:    params[:sign_off][:signer_name],
      signer_email:   params[:sign_off][:signer_email],
      signature_data: params[:sign_off][:signature_data],
      ip_address:     request.remote_ip,
      user_agent:     request.user_agent,
      token_digest:   Digest::SHA256.hexdigest(params[:token].to_s),
      signed_at:      Time.current,
      organization:   @defect.organization
    )

    if @sign_off.save
      @defect.update!(status: :signed_off)
      ActivityEvent.log!(defect: @defect, type: "defect.signed_off",
                         actor_label: "Resident: #{@sign_off.signer_name}",
                         metadata: { ip: request.remote_ip })
      render :thanks
    else
      flash.now[:alert] = "Please enter your name and draw your signature."
      render :new, status: :unprocessable_content
    end
  end

  private

  def load_defect
    @defect = Defect.find_signed!(params[:token], purpose: :resident_signoff)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render plain: "This sign-off link has expired or is invalid.", status: :gone
  end
end
