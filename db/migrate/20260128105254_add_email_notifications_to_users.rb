class AddEmailNotificationsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :emailnotifications, :boolean
  end
end
