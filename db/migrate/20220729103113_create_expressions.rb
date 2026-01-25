class CreateExpressions < ActiveRecord::Migration[6.1]
  def change
    create_table :expressions, id: :uuid do |t|

      t.uuid :userid
      t.uuid :docid
      t.string  :cfi
      t.string  :content

      t.timestamps
    end
  end
end
