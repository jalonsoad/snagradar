class CreateSlaPolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_policies do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :trade,        foreign_key: true, index: true   # optional: scope to a trade
      t.references :site,         foreign_key: true, index: true   # optional: scope to a site

      t.integer :priority,            null: false, default: 1  # low/medium/high/urgent
      t.integer :target_days,         null: false               # SLA window
      t.integer :amber_threshold_hours, null: false, default: 48 # warn this many hours before breach

      t.timestamps
    end

    add_index :sla_policies, [ :organization_id, :priority ]
  end
end
