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

      t.timestamps
    end
  end

end
