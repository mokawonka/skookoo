class CreateIdeas < ActiveRecord::Migration[6.1]
  def change
    create_table :ideas, id: :uuid do |t|

      t.uuid :userid
      t.uuid :docid
      t.string  :cfi
      t.string  :content

      t.timestamps
    end
  end
end
