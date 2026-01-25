class CreateReplies < ActiveRecord::Migration[6.1]
  def change
    create_table :replies, id: :uuid do |t|

      t.uuid :userid
      t.uuid :highlightid

      t.uuid :recipientid #parentid
      t.integer :score
      t.boolean :deleted

      t.boolean :edited

      t.timestamps
    end
  end
end
