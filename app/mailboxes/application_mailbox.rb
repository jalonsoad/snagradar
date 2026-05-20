class ApplicationMailbox < ActionMailbox::Base
  # defects@<org-slug>.snagradar.dev → InboundDefectsMailbox
  routing(/defects(\+[^@]+)?@/i => :inbound_defects)
end
