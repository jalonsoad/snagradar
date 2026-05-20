class AddTradeToContractorCompanies < ActiveRecord::Migration[8.1]
  def change
    add_reference :contractor_companies, :trade, foreign_key: true
  end
end
