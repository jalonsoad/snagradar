class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :defect,       null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true

      t.datetime :scheduled_at, null: false
      t.datetime :ends_at
      t.integer  :status, null: false, default: 0  # proposed/confirmed/attended/missed/cancelled
      t.text     :notes

      t.timestamps
    end

    add_index :appointments, [:organization_id, :scheduled_at]
  end
end
