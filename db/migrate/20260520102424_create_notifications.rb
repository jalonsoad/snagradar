class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient,    null: false, foreign_key: { to_table: :users }, index: true
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :defect,       foreign_key: true, index: true

      t.string   :channel,    null: false       # "email", "in_app"
      t.string   :event_type, null: false       # "defect.assigned", etc.
      t.string   :subject
      t.text     :preview
      t.integer  :status, null: false, default: 0   # pending/sent/failed/read
      t.datetime :sent_at
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:recipient_id, :read_at]
  end
end
