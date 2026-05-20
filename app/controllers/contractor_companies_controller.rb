class ContractorCompaniesController < AuthenticatedController
  before_action :set_company, only: %i[edit update destroy]

  def index
    @companies = Current.organization.contractor_companies.includes(:trade).order(:name)
  end

  def new;  @company = Current.organization.contractor_companies.build; end
  def edit; end

  def create
    @company = Current.organization.contractor_companies.build(company_params)
    if @company.save
      redirect_to contractor_companies_path, status: :see_other, notice: "Contractor added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @company.update(company_params)
      redirect_to contractor_companies_path, status: :see_other, notice: "Contractor updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @company.destroy
    redirect_to contractor_companies_path, status: :see_other, notice: "Contractor removed."
  end

  private

  def set_company
    @company = Current.organization.contractor_companies.find(params[:id])
  end

  def company_params
    params.expect(contractor_company: [:name, :contact_email, :phone, :trade_id])
  end
end
