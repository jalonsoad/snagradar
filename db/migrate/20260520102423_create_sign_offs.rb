class CreateSignOffs < ActiveRecord::Migration[8.1]
  def change
    create_table :sign_offs do |t|
      t.references :defect,       null: false, foreign_key: true, index: { unique: true }
      t.references :organization, null: false, foreign_key: true, index: true

      t.string   :signer_name,  null: false
      t.string   :signer_email
      t.text     :signature_data            # base64 PNG of the drawn signature (kept inline for evidence hash)
      t.string   :ip_address
      t.string   :user_agent
      t.string   :token_digest, null: false # so we can audit which magic-link token signed it
      t.datetime :signed_at,    null: false

      t.timestamps
    end
  end
end
