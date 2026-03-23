class CreateExpressions < ActiveRecord::Migration[6.1]
  def change
    create_table :expressions, id: :uuid do |t|

      t.uuid :userid
      t.uuid :docid
      t.string  :cfi
      t.string  :content

      t.string :definition, limit: 1000
      t.string :origin

      t.timestamps
    end
  end
end
