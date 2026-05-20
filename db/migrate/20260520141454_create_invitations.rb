class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :organization,  null: false, foreign_key: true, index: true
      t.references :invited_by,    null: false, foreign_key: { to_table: :users }, index: true
      t.references :accepted_user, foreign_key: { to_table: :users }, index: true

      t.string   :email_address, null: false
      t.string   :name
      t.integer  :role,          null: false, default: 0
      t.string   :token_digest,  null: false
      t.datetime :expires_at,    null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invitations, [:organization_id, :email_address]
    add_index :invitations, :token_digest, unique: true
  end
end
