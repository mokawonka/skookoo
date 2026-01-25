class CreateUsers < ActiveRecord::Migration[6.1]

  
  def change

    create_table :users, id: :uuid do |t|

      t.string :email
      t.string :username #handler
      t.string :password_digest
      t.string :password_confirmation
      t.string :name


      t.integer :mana
      t.text :votes
      t.boolean :darkmode
      t.string :font
      t.boolean :allownotifications
      t.uuid :hooked
      t.string :bio
      t.string :location

      t.text :following
      t.text :followers

      t.timestamps
    end

  end


end
