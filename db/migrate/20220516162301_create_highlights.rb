class CreateHighlights < ActiveRecord::Migration[6.1]
  def change
    create_table :highlights, id: :uuid do |t|

      t.uuid :userid
      t.uuid :docid
      t.string  :quote
      t.string  :fromauthors
      t.string  :fromtitle
      t.string  :cfi
      t.integer :score
      
      t.boolean :liked
      t.string  :comment
      t.string  :gifid
      t.string  :emojiid

      t.timestamps
    end
  end
end
