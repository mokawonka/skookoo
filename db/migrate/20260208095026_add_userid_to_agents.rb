class AddUseridToAgents < ActiveRecord::Migration[7.2]
  def change
    add_column :agents, :userid, :uuid
    add_index :agents, :userid
  end
end
