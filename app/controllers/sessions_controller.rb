class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  layout "auth", only: %i[ new ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  # Override Authentication#after_authentication_url so a direct sign-in
  # (with no stored return URL) lands on the dashboard, not the marketing root.
  def after_authentication_url
    session.delete(:return_to_after_authenticating) || dashboard_url
  end
end
