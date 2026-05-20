class CreateDefects < ActiveRecord::Migration[8.1]
  def change
    create_table :defects do |t|
      t.references :organization,        null: false, foreign_key: true, index: true
      t.references :site,                null: false, foreign_key: true, index: true
      t.references :plot,                foreign_key: true, index: true
      t.references :trade,               null: false, foreign_key: true, index: true
      t.references :contractor_company,  foreign_key: true, index: true
      t.references :reporter,            foreign_key: { to_table: :users }, index: true

      t.string  :reference         # Hyde / external reference
      t.string  :title,            null: false
      t.text    :description
      t.integer :priority,         null: false, default: 1  # low/medium/high/urgent
      t.integer :status,           null: false, default: 0  # logged/assigned/accepted/booked/in_progress/completed/signed_off/closed/rejected
      t.date    :sla_target_date
      t.datetime :assigned_at
      t.datetime :accepted_at
      t.datetime :completed_at
      t.datetime :closed_at

      t.timestamps
    end

    # Operational indexes
    add_index :defects, [:organization_id, :status]
    add_index :defects, [:organization_id, :sla_target_date]
    add_index :defects, [:site_id, :status]
    add_index :defects, [:contractor_company_id, :status]

    # Partial indexes for the most common dashboard queries
    add_index :defects, [:organization_id, :id], where: "status < 7", name: "idx_defects_open"
    add_index :defects, [:organization_id, :sla_target_date], where: "status < 7", name: "idx_defects_open_by_sla"
  end
end
