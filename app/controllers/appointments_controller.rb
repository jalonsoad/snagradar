class AppointmentsController < AuthenticatedController
  before_action :set_defect,      only: %i[create update destroy], if: :defect_scope?
  before_action :set_appointment, only: %i[update destroy]

  def index
    @start  = parse_anchor.beginning_of_week(:monday)
    @end    = (@start + 6.days).end_of_day

    @appointments = Current.organization.appointments
      .where(scheduled_at: @start..@end)
      .includes(defect: [ :site, :plot, :trade, :contractor_company ])
      .order(:scheduled_at)
    @by_day = @appointments.group_by { |a| a.scheduled_at.to_date }
    @counts = {
      total:      @appointments.size,
      confirmed:  @appointments.count { _1.status == "confirmed" },
      proposed:   @appointments.count { _1.status == "proposed" },
      attended:   @appointments.count { _1.status == "attended" }
    }
  end

  def create
    appt = @defect.appointments.build(appointment_params.merge(organization: Current.organization))
    appt.status ||= :proposed
    if appt.save
      ActivityEvent.log!(defect: @defect, type: "appointment.proposed", actor: Current.user,
                         metadata: { scheduled_at: appt.scheduled_at.iso8601 })
      @defect.update!(status: :booked) if %w[accepted].include?(@defect.status)
      redirect_to defect_path(@defect), status: :see_other, notice: "Appointment proposed."
    else
      redirect_to defect_path(@defect), status: :see_other, alert: appt.errors.full_messages.to_sentence
    end
  end

  def update
    if @appointment.update(appointment_params)
      ActivityEvent.log!(defect: @appointment.defect, type: "appointment.#{@appointment.status}",
                         actor: Current.user, metadata: { scheduled_at: @appointment.scheduled_at.iso8601 })
      redirect_to defect_path(@appointment.defect), status: :see_other, notice: "Appointment updated."
    else
      redirect_to defect_path(@appointment.defect), status: :see_other, alert: @appointment.errors.full_messages.to_sentence
    end
  end

  def destroy
    defect = @appointment.defect
    @appointment.update!(status: :cancelled)
    ActivityEvent.log!(defect: defect, type: "appointment.cancelled", actor: Current.user)
    redirect_to defect_path(defect), status: :see_other, notice: "Appointment cancelled."
  end

  private

  def defect_scope?
    params[:defect_id].present?
  end

  def set_defect
    @defect = Current.organization.defects.find(params[:defect_id])
  end

  def set_appointment
    @appointment = if @defect
      @defect.appointments.find(params[:id])
    else
      Current.organization.appointments.find(params[:id])
    end
  end

  def appointment_params
    params.expect(appointment: [ :scheduled_at, :ends_at, :status, :notes ])
  end

  def parse_anchor
    Date.parse(params[:date]) rescue Date.current
  rescue ArgumentError
    Date.current
  end
end
