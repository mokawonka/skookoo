class CreateDocuments < ActiveRecord::Migration[6.1]
  
  def change
    create_table :documents, id: :uuid do |t|

      t.uuid :epubid
      t.uuid :userid
      t.string :title
      t.string :authors

      t.boolean :ispublic # ignored at this moment
      t.decimal :progress
      t.integer :opened

      t.string :locations

      t.datetime :last_accessed_at

      t.integer :font_size, default: 18
      t.float :line_height, default: 1.6
      t.string :bg_color, default: "#ffffff"
      t.string :text_color, default: "#111111"
      t.string :font_family, default: "Crimson Pro"

      t.boolean :user_created, default: false, null: false

      # Formerly `type` (renamed to `nature`)
      t.string :nature, default: "book"

      t.index :last_accessed_at, name: "index_documents_on_last_accessed_at"

      t.timestamps
    end
  end

end
