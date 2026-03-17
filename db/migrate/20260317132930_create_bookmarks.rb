class CreateBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :bookmarks do |t|
      t.references :document, null: false, foreign_key: true, type: :uuid
      t.string  :cfi,        null: false
      t.float   :percentage, null: false, default: 0.0
      t.string  :label,      default: ''
      t.timestamps
    end
  end
end
