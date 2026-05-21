class CreateTestpageMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :testpage_messages do |t|
      t.string :body, null: false
      t.string :kind, null: false, default: "info"

      t.timestamps
    end
    add_index :testpage_messages, :created_at
  end
end
