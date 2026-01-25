class CreateEpubs < ActiveRecord::Migration[6.1]
  def change
    create_table :epubs, id: :uuid do |t|

      t.string :title
      t.string :authors
      t.string :lang

      t.string :sha3
      t.boolean :public_domain

      # epub file attached
      # cover picture attached

      t.timestamps
    end
  end
end
