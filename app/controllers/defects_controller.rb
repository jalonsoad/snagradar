class DefectsController < AuthenticatedController
  before_action :set_defect, only: %i[show edit update destroy assign accept reject complete reopen close]

  def index
    scope = Current.organization.defects.includes(:site, :plot, :trade, :contractor_company)
    scope = filter_status(scope)
    scope = filter_site(scope)
    scope = filter_query(scope)
    @defects = scope.recent.limit(100)
    @counts  = {
      open:       Current.organization.defects.open.count,
      overdue:    Current.organization.defects.overdue.count,
      amber:      Current.organization.defects.amber.count,
      signed_off: Current.organization.defects.signed_off_or_closed.count
    }
  end

  def show
    @comments        = @defect.comments.includes(:user).order(:created_at)
    @activity_events = @defect.activity_events.includes(:actor).order(:created_at)
    @new_comment     = @defect.comments.build
  end

  def new
    @defect = Current.organization.defects.build(sla_target_date: 7.days.from_now.to_date)
  end

  def create
    @defect = Current.organization.defects.build(defect_params)
    @defect.reporter = Current.user
    @defect.sla_target_date ||= default_sla_for(@defect)

    if @defect.save
      ActivityEvent.log!(defect: @defect, type: "defect.created", actor: Current.user,
                         metadata: { title: @defect.title, trade: @defect.trade&.name })
      broadcast_dashboard_update
      redirect_to defect_path(@defect), status: :see_other, notice: "Defect logged."
    else
      flash.now[:alert] = "Please fix the highlighted fields."
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @defect.update(defect_params)
      ActivityEvent.log!(defect: @defect, type: "defect.updated", actor: Current.user)
      redirect_to defect_path(@defect), status: :see_other, notice: "Defect updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @defect.destroy
    redirect_to defects_path, status: :see_other, notice: "Defect deleted."
  end

  # ─── State transitions ───────────────────────────────────────────
  def assign
    company = Current.organization.contractor_companies.find(params[:contractor_company_id])
    @defect.update!(contractor_company: company, status: :assigned, assigned_at: Time.current)
    ActivityEvent.log!(defect: @defect, type: "defect.assigned", actor: Current.user,
                       metadata: { contractor: company.name })
    broadcast_defect_changes
    redirect_to defect_path(@defect), status: :see_other, notice: "Assigned to #{company.name}."
  end

  def accept
    @defect.update!(status: :accepted, accepted_at: Time.current)
    ActivityEvent.log!(defect: @defect, type: "defect.accepted", actor: Current.user)
    broadcast_defect_changes
    redirect_to defect_path(@defect), status: :see_other, notice: "Defect accepted."
  end

  def reject
    @defect.update!(status: :rejected)
    ActivityEvent.log!(defect: @defect, type: "defect.rejected", actor: Current.user,
                       metadata: { reason: params[:reason] })
    broadcast_defect_changes
    redirect_to defect_path(@defect), status: :see_other, notice: "Defect rejected."
  end

  def complete
    @defect.update!(status: :completed, completed_at: Time.current)
    if params[:completion_photos].present?
      @defect.completion_photos.attach(params[:completion_photos])
    end
    ActivityEvent.log!(defect: @defect, type: "defect.completed", actor: Current.user)
    broadcast_defect_changes
    redirect_to defect_path(@defect), status: :see_other, notice: "Marked complete — awaiting sign-off."
  end

  def reopen
    @defect.update!(status: :logged, closed_at: nil)
    ActivityEvent.log!(defect: @defect, type: "defect.reopened", actor: Current.user)
    broadcast_defect_changes
    redirect_to defect_path(@defect), status: :see_other, notice: "Defect reopened."
  end

  def close
    @defect.update!(status: :closed, closed_at: Time.current)
    ActivityEvent.log!(defect: @defect, type: "defect.closed", actor: Current.user)
    broadcast_defect_changes
    redirect_to defect_path(@defect), status: :see_other, notice: "Defect closed."
  end

  private

  def set_defect
    @defect = Current.organization.defects.find(params[:id])
  end

  def defect_params
    params.expect(defect: [
      :site_id, :plot_id, :trade_id, :contractor_company_id, :reference,
      :title, :description, :priority, :sla_target_date,
      photos: []
    ])
  end

  def default_sla_for(defect)
    days = defect.trade&.default_sla_days || 7
    days.days.from_now.to_date
  end

  def filter_status(scope)
    case params[:filter]
    when "open"        then scope.open
    when "overdue"     then scope.overdue
    when "amber"       then scope.amber
    when "signed_off"  then scope.signed_off_or_closed
    else scope
    end
  end

  def filter_site(scope)
    return scope if params[:site_id].blank?
    scope.where(site_id: params[:site_id])
  end

  def filter_query(scope)
    return scope if params[:q].blank?
    scope.where("title ILIKE :q OR reference ILIKE :q", q: "%#{params[:q].strip}%")
  end

  def broadcast_dashboard_update
    # Phase 4 — Solid Cable / Turbo Streams: refresh dashboard counts + recent list
    # Defect.broadcast_replace_to([:org, Current.organization, :dashboard], ...) — wired later
  end

  def broadcast_defect_changes
    broadcast_dashboard_update
  end
end
