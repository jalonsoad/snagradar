class SearchesController < AuthenticatedController
  def index
    @q       = params[:q].to_s.strip
    @defects = Defect.none
    @sites   = Site.none

    if @q.length >= 2
      org = Current.organization
      needle = "%#{ActiveRecord::Base.sanitize_sql_like(@q)}%"

      @defects = org.defects
        .where("title ILIKE :q OR description ILIKE :q OR reference ILIKE :q", q: needle)
        .includes(:site, :plot, :trade)
        .order(updated_at: :desc)
        .limit(8)

      @sites = org.sites
        .where("name ILIKE :q OR reference ILIKE :q OR address ILIKE :q", q: needle)
        .order(:name)
        .limit(4)
    end

    respond_to do |format|
      format.html # full-page results
      format.json { render json: { defects: serialize(@defects), sites: @sites.as_json(only: %i[id name reference]) } }
    end
  end

  private

  def serialize(defects)
    defects.map do |d|
      {
        id: d.id,
        reference: d.reference,
        title: d.title,
        site: d.site&.name,
        plot: d.plot&.label,
        trade: d.trade&.name,
        status: d.status,
        sla_state: d.sla_state,
        url: Rails.application.routes.url_helpers.defect_path(d)
      }
    end
  end
end
