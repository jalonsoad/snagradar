class PlotsController < AuthenticatedController
  before_action :set_site

  def create
    plot = @site.plots.build(plot_params.merge(organization: Current.organization))
    if plot.save
      redirect_to site_path(@site), status: :see_other, notice: "Plot added."
    else
      redirect_to site_path(@site), status: :see_other, alert: plot.errors.full_messages.to_sentence
    end
  end

  def update
    plot = @site.plots.find(params[:id])
    plot.update(plot_params)
    redirect_to site_path(@site), status: :see_other
  end

  def destroy
    plot = @site.plots.find(params[:id])
    plot.destroy
    redirect_to site_path(@site), status: :see_other, notice: "Plot removed."
  end

  private

  def set_site
    @site = Current.organization.sites.find(params[:site_id])
  end

  def plot_params
    params.expect(plot: [ :plot_number, :address ])
  end
end
