class InvitationMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "SnagRadar <notify@snagradar.dev>") }

  def invite(invitation, plain_token:)
    @invitation = invitation
    @invited_by = invitation.invited_by
    @org        = invitation.organization
    @url        = accept_invitation_url(token: plain_token, host: default_host)

    mail(
      to:      invitation.email_address,
      subject: "You've been invited to #{@org.name} on SnagRadar"
    )
  end

  private

  def default_host
    ENV.fetch("APP_HOST", "localhost:3000")
  end
end
