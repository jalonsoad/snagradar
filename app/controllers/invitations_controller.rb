class InvitationsController < AuthenticatedController
  before_action :require_admin, except: %i[show update]
  allow_unauthenticated_access only: %i[show update]
  skip_before_action :require_organization,   only: %i[show update]
  skip_before_action :set_current_organization, only: %i[show update]
  # Tokenised accept flow (show/update) uses the marketing/auth split-panel
  # layout. Everything else inherits the authenticated dashboard layout.
  layout :resolve_layout

  def index
    @pending  = Current.organization.invitations.pending.order(created_at: :desc)
    @accepted = Current.organization.invitations.where.not(accepted_at: nil).order(accepted_at: :desc).limit(20)
  end

  def new
    @invitation = Current.organization.invitations.build(role: :care_coord)
  end

  def create
    @invitation = Current.organization.invitations.build(invitation_params)
    @invitation.invited_by = Current.user

    if @invitation.save
      InvitationMailer.invite(@invitation, plain_token: @invitation.token).deliver_later
      redirect_to invitations_path, status: :see_other,
                  notice: "Invitation sent to #{@invitation.email_address}."
    else
      flash.now[:alert] = "Please fix the highlighted fields."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    invitation = Current.organization.invitations.find(params[:id])
    invitation.destroy
    redirect_to invitations_path, status: :see_other, notice: "Invitation revoked."
  end

  # Public: shows the accept form
  def show
    @invitation = Invitation.find_by_token!(params[:token])
    @user = User.new(email_address: @invitation.email_address, name: @invitation.name)
  rescue ActiveRecord::RecordNotFound
    render plain: "This invitation has expired or already been used.", status: :gone
  end

  # Public: accept the invitation (set password + create user)
  def update
    @invitation = Invitation.find_by_token!(params[:token])

    @user = User.new(
      email_address: @invitation.email_address,
      name:          params.dig(:user, :name).presence || @invitation.name,
      organization:  @invitation.organization,
      role:          @invitation.role,
      password:              params.dig(:user, :password),
      password_confirmation: params.dig(:user, :password_confirmation)
    )

    ApplicationRecord.transaction do
      @user.save!
      @invitation.update!(accepted_user: @user, accepted_at: Time.current)
      start_new_session_for @user
    end

    redirect_to dashboard_path, status: :see_other,
                notice: "Welcome to #{@invitation.organization.name}!"
  rescue ActiveRecord::RecordNotFound
    render plain: "This invitation has expired or already been used.", status: :gone
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Please fix the highlighted fields."
    render :show, status: :unprocessable_content
  end

  private

  def require_admin
    redirect_to dashboard_path, alert: "Only admins can invite teammates." unless Current.user.role_admin?
  end

  def invitation_params
    params.expect(invitation: [ :email_address, :name, :role ])
  end

  def resolve_layout
    action_name.in?(%w[show update]) ? "auth" : "dashboard"
  end
end
