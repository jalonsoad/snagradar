class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :reference
      t.string :address
      t.integer :status

      t.timestamps
    end
  end
end
