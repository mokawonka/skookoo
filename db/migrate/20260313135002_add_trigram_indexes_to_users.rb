class AddTrigramIndexesToUsers < ActiveRecord::Migration[7.2]
  def up
    enable_extension :pg_trgm

    add_index :users, :username, using: :gist,
              opclass: :gist_trgm_ops,
              name: "index_users_on_username_trigram"

    add_index :users, :name, using: :gist,
              opclass: :gist_trgm_ops,
              name: "index_users_on_name_trigram"
  end

  def down
    remove_index :users, name: "index_users_on_username_trigram"
    remove_index :users, name: "index_users_on_name_trigram"
  end
end