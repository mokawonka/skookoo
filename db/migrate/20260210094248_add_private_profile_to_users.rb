class AddPrivateProfileToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :private_profile, :boolean, 
               default: false, 
               null: false
  end
end