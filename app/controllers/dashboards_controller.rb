class DashboardsController < AuthenticatedController
  def show
    org = Current.organization
    @counts = {
      open:         org.defects.open.count,
      overdue:      org.defects.overdue.count,
      amber:        org.defects.amber.count,
      signed_off:   org.defects.signed_off_or_closed.count
    }
    @recent_defects = org.defects.recent.limit(5).includes(:site, :plot, :trade, :contractor_company)
    @upcoming_appointments = org.appointments.upcoming.limit(5).includes(defect: [:site, :plot])
  end
end
