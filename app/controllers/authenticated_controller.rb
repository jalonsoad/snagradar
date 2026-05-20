# Base controller for every page behind authentication (the dashboard side).
# Inherits Authentication from ApplicationController and adds organisation
# scoping via Current.organization so that all queries can use `.for(Current.organization)`.
class AuthenticatedController < ApplicationController
  layout "dashboard"

  before_action :require_organization
  before_action :set_current_organization

  private

  def require_organization
    return if Current.user&.organization_id.present?
    # User has no org yet — push them to onboarding
    redirect_to new_organization_path, alert: "Set up your organisation to continue." if request.format.html?
  end

  def set_current_organization
    Current.organization = Current.user&.organization
  end
end
