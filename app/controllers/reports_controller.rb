require "csv"

class ReportsController < AuthenticatedController
  def index
    org = Current.organization
    @kpis = compute_kpis(org)
    @by_trade   = org.defects.open.group(:trade_id).count
                     .transform_keys { |id| org.trades.find_by(id: id)&.name || "—" }
    @by_site    = org.defects.open.group(:site_id).count
                     .transform_keys { |id| org.sites.find_by(id: id)&.name || "—" }
    @overdue_by_contractor = org.defects.overdue.group(:contractor_company_id).count
                     .transform_keys { |id| org.contractor_companies.find_by(id: id)&.name || "Unassigned" }
    @recurring = org.defects
                   .group(:plot_id, :trade_id)
                   .having("count(*) > 1")
                   .count
                   .map { |(plot_id, trade_id), n|
                     plot  = org.plots.find_by(id: plot_id)
                     trade = org.trades.find_by(id: trade_id)
                     { plot: plot, trade: trade, count: n } if plot && trade
                   }.compact
                    .sort_by { |r| -r[:count] }
                    .first(10)
  end

  def defects_csv
    org = Current.organization
    csv = CSV.generate(headers: true) do |out|
      out << %w[reference title site plot trade priority status sla_target_date contractor reporter
                logged_at assigned_at accepted_at completed_at closed_at]
      org.defects.includes(:site, :plot, :trade, :contractor_company, :reporter).find_each do |d|
        out << [
          d.reference, d.title, d.site&.name, d.plot&.label, d.trade&.name,
          d.priority, d.status, d.sla_target_date, d.contractor_company&.name,
          d.reporter&.display_name, d.created_at, d.assigned_at, d.accepted_at,
          d.completed_at, d.closed_at
        ]
      end
    end
    send_data csv, filename: "snagradar-defects-#{Date.current.iso8601}.csv", type: "text/csv"
  end

  private

  def compute_kpis(org)
    accepted    = org.defects.where.not(assigned_at: nil, accepted_at: nil)
    completed   = org.defects.where.not(assigned_at: nil, completed_at: nil)

    # Wrap raw SQL in Arel.sql so Rails 8 doesn't flag it as unsafe input.
    # No user data is interpolated — these are hard-coded aggregates.
    avg_acceptance_h = accepted.pick(Arel.sql("AVG(EXTRACT(EPOCH FROM (accepted_at - assigned_at)) / 3600)"))
    avg_completion_d = completed.pick(Arel.sql("AVG(EXTRACT(EPOCH FROM (completed_at - assigned_at)) / 86400)"))
    signed_off_rate  = begin
      total = org.defects.where.not(completed_at: nil).count.to_f
      total.zero? ? 0 : (org.defects.signed_off_or_closed.count / total * 100)
    end

    {
      total_open:        org.defects.open.count,
      total_overdue:     org.defects.overdue.count,
      avg_acceptance_h:  avg_acceptance_h&.to_f&.round(1),
      avg_completion_d:  avg_completion_d&.to_f&.round(1),
      signoff_rate:      signed_off_rate.round(0),
      open_defects_by_priority: org.defects.open.group(:priority).count
    }
  end
end
