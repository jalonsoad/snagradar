namespace :demo do
  desc "Seed (or reseed) the Invoxi demo account with historical data — Jan 1 2026 → today"
  task seed_invoxi: :environment do
    require "securerandom"

    puts "▸ Seeding Invoxi demo account…"

    # ─── Tear down any previous Invoxi data so the task is idempotent ────
    if (existing = Organization.find_by(slug: "invoxi"))
      # Defects must go before sites/plots because Site->Defect is :nullify
      # but defects.site_id is NOT NULL — without this the cascade fails.
      existing.defects.find_each(&:destroy)
      existing.appointments.destroy_all
      existing.activity_events.destroy_all
      existing.notifications.destroy_all
      existing.destroy
      puts "  ✓ Removed previous Invoxi organization (cascaded children)"
    end

    # Org has_many :users, dependent: :nullify — the admin user survives the
    # org destroy, so wipe it explicitly before recreating.
    User.where(email_address: "info@invoxi.com").destroy_all

    org = Organization.create!(name: "Invoxi", slug: "invoxi", status: :active)
    admin = User.new(email_address: "info@invoxi.com", name: "Invoxi Admin", organization: org, role: :admin)
    admin.password = admin.password_confirmation = "password123"
    admin.save!
    puts "  ✓ Organisation: #{org.name} (slug: #{org.slug})"
    puts "  ✓ Admin user:   #{admin.email_address} / password123"

    # ─── Trades ───────────────────────────────────────────────────────────
    trade_specs = [
      [ "Plumbing",   3 ],
      [ "Electrical", 2 ],
      [ "Carpentry",  5 ],
      [ "Decorating", 7 ],
      [ "Tiling",     5 ],
      [ "Roofing",    7 ],
      [ "Glazing",    5 ],
      [ "Heating",    4 ]
    ]
    trades = trade_specs.to_h { |name, sla| [ name, org.trades.create!(name: name, default_sla_days: sla) ] }
    puts "  ✓ #{trades.size} trades"

    # ─── Sites + plots ────────────────────────────────────────────────────
    site_specs = [
      [ "Camden Heights",   "INV-CMD", "Camden Road, London, NW1",     %w[01 02 03 04 05 06 07 08 09 10 11 12] ],
      [ "Brighton Marina",  "INV-BMR", "King's Road, Brighton, BN2",   %w[A1 A2 A3 A4 B1 B2 B3 B4 C1 C2] ],
      [ "Manchester Mills", "INV-MMS", "Ancoats, Manchester, M4",      %w[01 02 03 04 05 06 07 08] ],
      [ "Bristol Wharf",    "INV-BWF", "Floating Harbour, Bristol, BS1", %w[01 02 03 04 05 06] ]
    ]
    sites = site_specs.map do |name, ref, address, plot_numbers|
      site = org.sites.create!(name: name, reference: ref, address: address, status: :active)
      plot_numbers.each { |pn| site.plots.create!(organization: org, plot_number: pn) }
      site
    end
    puts "  ✓ #{org.sites.count} sites with #{org.plots.count} plots"

    # ─── Contractor companies ─────────────────────────────────────────────
    contractor_specs = [
      [ "Marlow Plumbing & Heating",  trades["Plumbing"],   "ops@marlow-ph.co.uk",     "+44 20 7100 1100" ],
      [ "Westbrook Electrics",        trades["Electrical"], "info@westbrook-elec.uk",  "+44 20 7100 2200" ],
      [ "Hartley Joinery Ltd",        trades["Carpentry"],  "shop@hartley-joinery.uk", "+44 20 7100 3300" ],
      [ "Belmont Decorating Co.",     trades["Decorating"], "studio@belmont-dec.co.uk", "+44 20 7100 4400" ],
      [ "Riverside Tiling Services",  trades["Tiling"],     "team@riverside-tiling.uk", "+44 20 7100 5500" ],
      [ "Stonebridge Roofing",        trades["Roofing"],    "office@stonebridge-rf.uk", "+44 20 7100 6600" ]
    ]
    contractors = contractor_specs.map do |name, trade, email, phone|
      org.contractor_companies.create!(name: name, trade: trade, contact_email: email, phone: phone)
    end
    puts "  ✓ #{contractors.size} contractor companies"

    # ─── Defect catalogue (titles + descriptions per trade) ───────────────
    title_pool = {
      "Plumbing"   => [
        [ "Leak under kitchen sink",         "Slow drip from the U-bend — pooling in the cabinet." ],
        [ "Hot water intermittently cold",   "Resident reports tepid water for 5–10 min before recovering." ],
        [ "Toilet cistern continuously fills", "Float valve appears not to seat properly." ],
        [ "Shower mixer dripping",            "Constant drip even when fully off." ],
        [ "Bath tap stiff to turn",           "Cartridge likely seized; needs swap." ]
      ],
      "Electrical" => [
        [ "Hallway lights flickering",       "Random flicker, both LEDs replaced — issue persists." ],
        [ "Socket dead in master bed",       "USB sockets next to bed have no power." ],
        [ "Smoke alarm chirping",            "Hush button reset doesn't stop the chirp." ],
        [ "Extractor fan rattling",          "Bathroom fan noisy when triggered." ],
        [ "Doorbell intermittent",           "Sometimes rings, sometimes not — wiring check." ]
      ],
      "Carpentry"  => [
        [ "Front door drags on threshold",   "Catches on the strip — needs planing." ],
        [ "Wardrobe handle loose",           "Resident has retightened; coming back loose." ],
        [ "Kitchen drawer off runner",       "Slid off after heavy load — runner damaged." ],
        [ "Skirting separated from wall",    "Section pulled away in hallway." ],
        [ "Loft hatch sticks shut",          "Needs ease + relubrication." ]
      ],
      "Decorating" => [
        [ "Touch-up paint, master bed",      "Bump damage during move-in." ],
        [ "Filler cracks on bedroom ceiling", "Hairline crack near light fitting." ],
        [ "Mismatched paint on patch",       "Earlier touch-up doesn't match sheen." ],
        [ "Wall paint scuffed in hallway",   "Significant scuff on the feature wall." ],
        [ "Window frame paint chipped",      "Chipped corner near the latch." ]
      ],
      "Tiling"     => [
        [ "Loose tile, ensuite floor",       "Tile lifts when stepped on." ],
        [ "Grout crumbling near shower",     "Long-term wet area — regrout needed." ],
        [ "Hairline crack across tile",      "Single cracked tile near WC." ],
        [ "Silicone mouldy around bath",     "Resident asks for replacement silicone." ]
      ],
      "Roofing"    => [
        [ "Slipped tile above bay window",   "Spotted from street level." ],
        [ "Gutter overflowing in heavy rain", "Likely blocked at downpipe junction." ],
        [ "Leak through chimney flashing",   "Damp patch on bedroom ceiling." ]
      ],
      "Glazing"    => [
        [ "Misted double glazing, lounge",   "Failed seal between panes." ],
        [ "Window won't fully close",        "Top hung sash needs adjustment." ],
        [ "Window restrictor sticking",      "Lock not retracting smoothly." ]
      ],
      "Heating"    => [
        [ "Radiator cold in master bed",     "Needs bleeding or balance." ],
        [ "Boiler dropping pressure",        "Resident topping up weekly — investigate." ],
        [ "Thermostat unresponsive",         "Wireless link drops every other day." ]
      ]
    }

    # ─── Defect generation — Jan 1 → today, weighted statuses ─────────────
    start_date = Date.new(2026, 1, 1)
    today      = Date.current
    span_days  = (today - start_date).to_i
    priorities = %i[low low medium medium medium high high urgent]

    status_weights = {
      closed:      28,
      signed_off:  22,
      completed:   10,
      in_progress: 12,
      booked:       6,
      accepted:     6,
      assigned:     6,
      logged:       6,
      rejected:     2,
      overdue_open: 2   # synthetic: open with past SLA target
    }
    weight_total = status_weights.values.sum
    weighted_pool = status_weights.flat_map { |status, w| Array.new(w, status) }

    total_defects = 250
    sla_within_rate = 0.82   # ~18 % breach to give the gauge variation

    created_refs = []
    total_defects.times do |i|
      created_at = (start_date + rand(span_days).days).to_time + rand(8..18).hours + rand(60).minutes
      trade_name = title_pool.keys.sample
      trade      = trades[trade_name]
      title, description = title_pool[trade_name].sample
      site       = sites.sample
      plot       = site.plots.sample
      contractor = contractors.find { |c| c.trade_id == trade.id } || contractors.sample
      priority   = priorities.sample
      target_status = weighted_pool.sample
      sla_days   = trade.default_sla_days
      sla_target = created_at.to_date + sla_days.days

      defect = Defect.new(
        organization:       org,
        site:               site,
        plot:               plot,
        trade:              trade,
        contractor_company: contractor,
        reporter:           admin,
        reference:          "INV-#{(1000 + i)}",
        title:              title,
        description:        description,
        priority:           priority,
        sla_target_date:    sla_target,
        created_at:         created_at,
        updated_at:         created_at
      )

      assigned_at  = nil
      accepted_at  = nil
      completed_at = nil
      closed_at    = nil
      final_status = target_status

      case target_status
      when :logged
        # nothing
      when :assigned
        assigned_at = created_at + rand(2..36).hours
      when :accepted
        assigned_at = created_at + rand(2..18).hours
        accepted_at = assigned_at + rand(2..18).hours
      when :booked, :in_progress
        assigned_at = created_at + rand(2..18).hours
        accepted_at = assigned_at + rand(2..12).hours
      when :completed, :signed_off, :closed
        assigned_at  = created_at + rand(1..12).hours
        accepted_at  = assigned_at + rand(1..12).hours
        within_sla   = rand < sla_within_rate
        completion_offset_days =
          if within_sla
            rand(0..(sla_days - 1).clamp(1, 30))
          else
            sla_days + rand(1..6)
          end
        completed_at = (created_at + completion_offset_days.days + rand(8..16).hours).clamp(created_at + 1.hour, Time.current)
        closed_at    = completed_at + rand(4..72).hours if target_status == :closed
        # If we'd be in the future, demote to in_progress
        if completed_at > Time.current
          completed_at = nil
          final_status = :in_progress
        end
      when :rejected
        assigned_at  = created_at + rand(2..18).hours
      when :overdue_open
        # Force an open defect with a past SLA target (red on the gauge).
        defect.sla_target_date = today - rand(1..10).days
        assigned_at  = created_at + rand(2..18).hours
        accepted_at  = assigned_at + rand(2..12).hours
        final_status = %i[accepted booked in_progress].sample
      end

      defect.assigned_at  = assigned_at
      defect.accepted_at  = accepted_at
      defect.completed_at = completed_at
      defect.closed_at    = closed_at
      defect.status       = final_status

      defect.save!(validate: false)
      # Force created_at after save (Rails resets timestamps on save).
      defect.update_columns(created_at: created_at, updated_at: (completed_at || closed_at || assigned_at || created_at))
      created_refs << defect.id
    end
    puts "  ✓ #{Defect.where(organization: org).count} defects (Jan 1 → today)"

    # ─── Appointments — for ~40 % of accepted/booked/in_progress/completed defects ────
    appt_candidates = Defect.where(organization: org, status: %i[accepted booked in_progress completed signed_off closed])
    appt_count = 0
    appt_candidates.find_each do |d|
      next unless rand < 0.4
      base = d.completed_at || (d.accepted_at || d.created_at) + rand(1..5).days
      next if base.nil?

      status = case d.status
      when "completed", "signed_off", "closed" then :attended
      when "in_progress", "booked"             then :confirmed
      else                                          :proposed
      end

      Appointment.create!(
        organization: org,
        defect:       d,
        scheduled_at: base,
        ends_at:      base + rand(30..120).minutes,
        status:       status,
        notes:        [ "Visit confirmed by resident", "Will need parking permit", "Spare key with concierge", "Resident wfh on the day" ].sample
      )
      appt_count += 1
    end

    # A handful of upcoming visits (next 2 weeks) for the "Upcoming" dashboard list.
    Defect.where(organization: org, status: %i[booked accepted]).limit(8).each do |d|
      Appointment.create!(
        organization: org,
        defect:       d,
        scheduled_at: rand(1..14).days.from_now.change(hour: rand(9..16)),
        ends_at:      nil,
        status:       :confirmed,
        notes:        "Routine inspection slot"
      )
      appt_count += 1
    end
    puts "  ✓ #{appt_count} appointments"

    # ─── Comments — light scatter ────────────────────────────────────────
    comment_lines = [
      "Resident confirmed availability for Wednesday morning.",
      "Trade rang — needs additional part, ETA 2 days.",
      "Site manager has the key, no need to coordinate with resident.",
      "Pictures attached from the initial walk-round.",
      "Spoke with contractor — booked in for next week.",
      "Customer satisfied with the work — closing out."
    ]
    comment_count = 0
    Defect.where(organization: org).order("RANDOM()").limit(60).each do |d|
      rand(1..3).times do
        Comment.create!(
          organization: org,
          defect:       d,
          user:         admin,
          body:         comment_lines.sample,
          visibility:   :internal
        )
        comment_count += 1
      end
    end
    puts "  ✓ #{comment_count} comments"

    puts "▸ Done. Sign in at /session/new with info@invoxi.com / password123"
  end
end
