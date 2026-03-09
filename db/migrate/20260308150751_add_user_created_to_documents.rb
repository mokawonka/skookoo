class AddUserCreatedToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :user_created, :boolean, default: false, null: false
  end
end
