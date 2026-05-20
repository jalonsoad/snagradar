class CreateContractorMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :contractor_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :contractor_company, null: false, foreign_key: true
      t.integer :role

      t.timestamps
    end
  end
end
