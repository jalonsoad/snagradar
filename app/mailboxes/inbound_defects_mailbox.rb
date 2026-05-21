# Incoming emails to defects@<org-slug>.snagradar.dev create a Defect.
#
# Routing examples:
#   defects@acme.snagradar.dev          → org resolved by subdomain "acme"
#   defects+adur@acme.snagradar.dev     → org "acme", site hint "adur"
#   defects+adur-14@acme.snagradar.dev  → org "acme", site "adur", plot 14
#
# Subject + body are passed through DefectClassifier (rules first; ready
# to be swapped for an LLM via the same interface). Attachments are
# attached as defect photos via Active Storage.
class InboundDefectsMailbox < ApplicationMailbox
  before_processing :ensure_organization

  def process
    site, plot = resolve_site_and_plot
    body_text  = mail.body.to_s.then { |b| ActionView::Base.full_sanitizer.sanitize(b) }
    suggestion = DefectClassifier.suggest("#{mail.subject} #{body_text}", organization: organization)

    defect = organization.defects.create!(
      site:        site || organization.sites.order(:created_at).first,
      plot:        plot,
      trade:       organization.trades.find_by(id: suggestion[:trade_id]) ||
                   organization.trades.find_by("LOWER(name) = ?", "general") ||
                   organization.trades.order(:created_at).first,
      title:       (mail.subject.presence || "Defect via email")[0, 200],
      description: body_text.to_s[0, 4_000],
      priority:    suggestion[:priority].presence || "medium",
      status:      :logged,
      sla_target_date: default_sla(suggestion)
    )

    attach_photos!(defect)

    ActivityEvent.log!(defect: defect, type: "defect.email_intake",
                       actor_label: "Email: #{mail.from.first}",
                       metadata: {
                         subject: mail.subject, from: mail.from.first,
                         classifier: suggestion.slice(:trade_name, :priority, :matched_keywords)
                       })
  end

  private

  def organization
    @organization ||= begin
      slug = mail.recipients.lazy.map { |to| to.to_s.split("@", 2).last.to_s.split(".").first }.find(&:present?)
      Organization.find_by(slug: slug) || Organization.first
    end
  end

  def ensure_organization
    bounce_with(InboundDefectsMailer.unrouted(inbound_email)) and return false unless organization
  rescue NameError
    # If the mailer doesn't exist we still want to abort processing
    bounced! unless organization
  end

  def resolve_site_and_plot
    # defects+adur-14@acme.snagradar.dev → ["adur", "14"]
    sub_address = mail.recipients.lazy.map { |a| a.to_s[/\+([^@]+)@/, 1] }.find(&:present?)
    return [ nil, nil ] unless sub_address

    site_hint, plot_hint = sub_address.split("-", 2).map(&:strip)
    # sanitize_sql_like escapes %/_ so a malicious sub-address can't widen the
    # match. The ? bind param already prevents SQL injection — this is defense
    # against pattern injection.
    needle = "%#{ActiveRecord::Base.sanitize_sql_like(site_hint.downcase)}%"
    site = organization.sites.where("LOWER(name) LIKE ?", needle).first ||
           organization.sites.find_by(reference: site_hint)
    plot = site&.plots&.find_by(plot_number: plot_hint) if plot_hint && site
    [ site, plot ]
  end

  def default_sla(suggestion)
    days = case suggestion[:priority]
    when "urgent" then 1
    when "high"   then 2
    when "medium" then 5
    else 7
    end
    days.days.from_now.to_date
  end

  def attach_photos!(defect)
    mail.attachments.each do |attachment|
      next unless attachment.content_type.to_s.start_with?("image/")
      defect.photos.attach(
        io:           StringIO.new(attachment.body.to_s),
        filename:     attachment.filename || "photo-#{SecureRandom.hex(4)}.jpg",
        content_type: attachment.content_type
      )
    end
  end
end
