class CreateContractorCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :contractor_companies do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :contact_email
      t.string :phone

      t.timestamps
    end
  end
end
