class CreatePlots < ActiveRecord::Migration[8.1]
  def change
    create_table :plots do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.string :plot_number
      t.string :address

      t.timestamps
    end
  end
end
