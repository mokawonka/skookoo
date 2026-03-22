class CreateReposts < ActiveRecord::Migration[7.2]
  def change
    create_table :reposts, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :highlight, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :reposts, [:user_id, :highlight_id], unique: true
  end
end