class CreateActivityEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_events do |t|
      t.references :defect,       null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :actor,        foreign_key: { to_table: :users }, index: true  # nullable for system events

      t.string :event_type, null: false  # e.g. "defect.created", "defect.assigned", "appointment.proposed"
      t.string :actor_label                # "Robson Plumbing", "System", "Resident"
      t.jsonb  :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :activity_events, [ :defect_id, :created_at ]
    add_index :activity_events, [ :organization_id, :created_at ]
  end
end
