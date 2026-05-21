class SitesController < AuthenticatedController
  before_action :set_site, only: %i[show edit update destroy]

  def index
    @sites = Current.organization.sites.order(:name).includes(:plots)
  end

  def show
    @plots = @site.plots.order(:plot_number)
    @open_defects_count = @site.defects.open.count
  end

  def new
    @site = Current.organization.sites.build
  end

  def create
    @site = Current.organization.sites.build(site_params)
    if @site.save
      redirect_to site_path(@site), status: :see_other, notice: "Site created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @site.update(site_params)
      redirect_to site_path(@site), status: :see_other, notice: "Site updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @site.destroy
    redirect_to sites_path, status: :see_other, notice: "Site removed."
  end

  private

  def set_site
    @site = Current.organization.sites.find(params[:id])
  end

  def site_params
    params.expect(site: [ :name, :reference, :address, :status ])
  end
end
