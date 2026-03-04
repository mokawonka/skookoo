class CreateFeatureRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :feature_requests, id: :uuid do |t|
      t.string :title
      t.text :description
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :status
      t.integer :priority

      t.timestamps
    end
  end
end
