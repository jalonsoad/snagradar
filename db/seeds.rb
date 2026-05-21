# Idempotent dev/demo seeds — safe to run multiple times.
#
# Login after running `bin/rails db:seed`:
#   email:    demo@snagradar.dev
#   password: password123

puts "▸ Seeding demo data…"

# ─── Organisation + admin user ────────────────────────────────────────
org = Organization.find_or_create_by!(slug: "demo-co") do |o|
  o.name   = "PMC Customer Care"
  o.status = :active
end

admin = User.find_or_initialize_by(email_address: "demo@snagradar.dev")
admin.assign_attributes(name: "Demo Admin", organization: org, role: :admin)
admin.password = admin.password_confirmation = "password123"
admin.save!

puts "  ✓ Organisation: #{org.name} (slug: #{org.slug})"
puts "  ✓ Admin user:   #{admin.email_address} / password123"

# ─── Default trades ───────────────────────────────────────────────────
[
  [ "Plumbing",   3 ],
  [ "Electrical", 2 ],
  [ "Carpentry",  5 ],
  [ "Decorating", 7 ],
  [ "Tiling",     5 ],
  [ "Roofing",    7 ],
  [ "Glazing",    5 ],
  [ "General",    7 ]
].each do |name, sla|
  org.trades.find_or_create_by!(name: name) { |t| t.default_sla_days = sla }
end
puts "  ✓ #{org.trades.count} trades"

# ─── Sample sites + plots ─────────────────────────────────────────────
adur = org.sites.find_or_create_by!(name: "Adur Shoreham") do |s|
  s.reference = "HYD-ADUR"
  s.address   = "Shoreham-by-Sea, BN43"
end
%w[01 02 03 04 05 14 21].each do |n|
  adur.plots.find_or_create_by!(plot_number: n) { |p| p.organization = org }
end

bridgewood = org.sites.find_or_create_by!(name: "Bridgewood Park") do |s|
  s.reference = "HYD-BWD"
  s.address   = "Reigate, RH2"
end
%w[A1 A2 A3].each do |n|
  bridgewood.plots.find_or_create_by!(plot_number: n) { |p| p.organization = org }
end
puts "  ✓ #{org.sites.count} sites with #{org.plots.count} plots"

# ─── Contractor companies ─────────────────────────────────────────────
plumbing = org.trades.find_by!(name: "Plumbing")
electrical = org.trades.find_by!(name: "Electrical")
decorating = org.trades.find_by!(name: "Decorating")

[
  [ "Robson Plumbing",  plumbing,   "contact@robson-plumb.co.uk", "+44 20 7000 1110" ],
  [ "Crown Electrics",  electrical, "ops@crown-elec.co.uk",       "+44 20 7000 2220" ],
  [ "Pemberton Decor",  decorating, "studio@pemberton-decor.uk",  "+44 20 7000 3330" ]
].each do |name, trade, email, phone|
  org.contractor_companies.find_or_create_by!(name: name) do |c|
    c.trade = trade; c.contact_email = email; c.phone = phone
  end
end
puts "  ✓ #{org.contractor_companies.count} contractor companies"

# ─── A handful of defects across SLA states ──────────────────────────
robson    = org.contractor_companies.find_by!(name: "Robson Plumbing")
crown     = org.contractor_companies.find_by!(name: "Crown Electrics")
pemberton = org.contractor_companies.find_by!(name: "Pemberton Decor")

[
  { ref: "HY-2487", site: adur, plot: "14", trade: plumbing,
    title: "Leak under kitchen sink", priority: :high,
    contractor: robson, sla: 3.days.from_now, status: :booked },
  { ref: "HY-2491", site: adur, plot: "02", trade: electrical,
    title: "Hallway light flickering", priority: :medium,
    contractor: crown, sla: 36.hours.from_now, status: :accepted },
  { ref: "HY-2451", site: adur, plot: "04", trade: plumbing,
    title: "Leak under bathroom sink", priority: :urgent,
    contractor: robson, sla: 2.days.ago, status: :assigned },
  { ref: "HY-2495", site: adur, plot: "08", trade: decorating,
    title: "Touch-up paint, master bed", priority: :low,
    contractor: pemberton, sla: 6.days.from_now, status: :logged },
  { ref: "HY-2502", site: bridgewood, plot: "A1", trade: decorating,
    title: "Skirting board scuff, living room", priority: :low,
    contractor: pemberton, sla: 8.days.from_now, status: :completed }
].each do |attrs|
  plot = attrs[:plot].is_a?(String) ? attrs[:site].plots.find_by(plot_number: attrs[:plot]) : attrs[:plot]
  Defect.find_or_create_by!(reference: attrs[:ref], organization: org) do |d|
    d.site               = attrs[:site]
    d.plot               = plot
    d.trade              = attrs[:trade]
    d.contractor_company = attrs[:contractor]
    d.reporter           = admin
    d.title              = attrs[:title]
    d.priority           = attrs[:priority]
    d.status             = attrs[:status]
    d.sla_target_date    = attrs[:sla]
  end
end
puts "  ✓ #{org.defects.count} sample defects"

puts ""
puts "▸ Done. Sign in at /session/new with demo@snagradar.dev / password123"
