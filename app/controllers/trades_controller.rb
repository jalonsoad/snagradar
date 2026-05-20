class TradesController < AuthenticatedController
  before_action :set_trade, only: %i[edit update destroy]

  def index
    @trades = Current.organization.trades.order(:name)
  end

  def new;  @trade = Current.organization.trades.build; end
  def edit; end

  def create
    @trade = Current.organization.trades.build(trade_params)
    if @trade.save
      redirect_to trades_path, status: :see_other, notice: "Trade added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @trade.update(trade_params)
      redirect_to trades_path, status: :see_other, notice: "Trade updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @trade.destroy
    redirect_to trades_path, status: :see_other, notice: "Trade removed."
  end

  private

  def set_trade
    @trade = Current.organization.trades.find(params[:id])
  end

  def trade_params
    params.expect(trade: [:name, :default_sla_days])
  end
end
