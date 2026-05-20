class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :defect,       null: false, foreign_key: true, index: true
      t.references :user,         null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true

      t.text    :body, null: false
      t.integer :visibility, null: false, default: 0  # internal/external

      t.timestamps
    end

    add_index :comments, [:defect_id, :created_at]
  end
end
