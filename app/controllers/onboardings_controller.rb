# Onboarding wizard — currently just one step: create an organisation
# and attach the current user as admin.
class OnboardingsController < ApplicationController
  layout "auth"

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(onboarding_params)

    ApplicationRecord.transaction do
      @organization.save!
      Current.user.update!(organization: @organization, role: :admin)
      seed_default_trades(@organization)
    end

    redirect_to dashboard_path, status: :see_other, notice: "Organisation ready — welcome aboard."
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Pick an organisation name to continue."
    render :new, status: :unprocessable_content
  end

  private

  def onboarding_params
    params.expect(organization: [ :name ])
  end

  DEFAULT_TRADES = [
    [ "Plumbing",   3 ],
    [ "Electrical", 2 ],
    [ "Carpentry",  5 ],
    [ "Decorating", 7 ],
    [ "Tiling",     5 ],
    [ "Roofing",    7 ],
    [ "Glazing",    5 ],
    [ "General",    7 ]
  ].freeze

  def seed_default_trades(org)
    DEFAULT_TRADES.each do |name, sla|
      org.trades.create!(name: name, default_sla_days: sla)
    end
  end
end
