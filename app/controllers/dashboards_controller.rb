class DashboardsController < AuthenticatedController
  def show
    org = Current.organization

    @counts = {
      open:       org.defects.open.count,
      overdue:    org.defects.overdue.count,
      amber:      org.defects.amber.count,
      signed_off: org.defects.signed_off_or_closed.count
    }

    @recent_defects        = org.defects.recent.limit(5).includes(:site, :plot, :trade, :contractor_company)
    # Upcoming list shows defect.trade + defect.site — eager-load those.
    # Don't include :plot (Bullet flags it as unused eager loading).
    @upcoming_appointments = org.appointments.upcoming.limit(5).includes(defect: [ :site, :trade ])

    # ─── Geckoboard-style chart data for the complaints manager ──────
    @chart = build_dashboard_charts(org)
  end

  private

  # Returns a hash of pre-computed series for ApexCharts. Each value is
  # already JSON-safe (numbers / strings / arrays).
  def build_dashboard_charts(org)
    window_days = 14
    today       = Date.current
    start_day   = today - (window_days - 1)

    # Daily intake (defects created) and resolved (completed) buckets.
    intake_by_day   = org.defects
                         .where(created_at: start_day.beginning_of_day..today.end_of_day)
                         .group(Arel.sql("DATE(created_at)")).count
    resolved_by_day = org.defects
                         .where(completed_at: start_day.beginning_of_day..today.end_of_day)
                         .group(Arel.sql("DATE(completed_at)")).count

    categories  = (start_day..today).map { |d| d.strftime("%-d %b") }
    intake_data = (start_day..today).map { |d| intake_by_day[d].to_i }
    closed_data = (start_day..today).map { |d| resolved_by_day[d].to_i }

    # Status breakdown for the donut. Rails enums return string keys from
    # `.group(:status).count`, so look up by name (not integer).
    status_counts = org.defects.group(:status).count
    status_labels = %w[logged assigned accepted booked in_progress completed signed_off closed rejected]
    status_series = status_labels.map { |s| status_counts[s].to_i }

    # By-trade horizontal bar — open defects only, top 6 trades.
    trade_counts  = org.defects.open.joins(:trade).group(Arel.sql("trades.name")).count
    trade_top     = trade_counts.sort_by { |_, v| -v }.first(6)
    trade_labels  = trade_top.map(&:first)
    trade_data    = trade_top.map(&:last)

    # SLA compliance — % of resolved defects that closed on or before sla_target_date.
    resolved   = org.defects.signed_off_or_closed.where.not(completed_at: nil, sla_target_date: nil)
    total_done = resolved.count
    within_sla = resolved.where("DATE(completed_at) <= sla_target_date").count
    sla_pct    = total_done.positive? ? ((within_sla.to_f / total_done) * 100).round : 0

    # Average resolution hours (last 30 days of completed work).
    avg_seconds = org.defects.where(completed_at: 30.days.ago..)
                              .pick(Arel.sql("AVG(EXTRACT(EPOCH FROM (completed_at - created_at)))"))
                              .to_f
    avg_hours   = avg_seconds.positive? ? (avg_seconds / 3600.0).round(1) : nil

    {
      categories:    categories,
      intake_data:   intake_data,
      closed_data:   closed_data,
      status_labels: status_labels,
      status_series: status_series,
      trade_labels:  trade_labels,
      trade_data:    trade_data,
      sla_pct:       sla_pct,
      avg_hours:     avg_hours,
      total_done:    total_done,
      backlog:       intake_data.sum - closed_data.sum
    }
  end
end
