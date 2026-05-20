class AddOrganizationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :organization, null: false, foreign_key: true
    add_column :users, :name, :string
    add_column :users, :role, :integer
  end
end
