class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  layout "auth"

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      redirect_to new_onboarding_path, status: :see_other,
                  notice: "Welcome to SnagRadar — let's set up your organisation."
    else
      flash.now[:alert] = "Please fix the highlighted fields."
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.expect(user: [:name, :email_address, :password, :password_confirmation])
  end
end
