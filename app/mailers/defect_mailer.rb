class DefectMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "SnagRadar <notify@snagradar.dev>") }

  def assigned(defect, contractor_email: nil)
    @defect    = defect
    @site      = defect.site
    @plot      = defect.plot
    @trade     = defect.trade
    @token_url = contractor_portal_url(token: defect.contractor_token, host: default_host)

    mail(
      to:      contractor_email || defect.contractor_company&.contact_email,
      subject: "[SnagRadar] Defect assigned — #{defect.reference || "##{defect.id}"} · #{defect.title}"
    )
  end

  def signoff_request(defect, resident_email:)
    @defect    = defect
    @token_url = resident_signoff_url(token: defect.resident_signoff_token, host: default_host)

    mail(
      to:      resident_email,
      subject: "[SnagRadar] Please sign off your completed work — #{defect.site&.name}"
    )
  end

  private

  def default_host
    ENV.fetch("APP_HOST", "localhost:3000")
  end
end
