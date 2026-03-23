class CreateAgents < ActiveRecord::Migration[7.2]
  def change
    create_table :agents, id: :uuid do |t|
      t.string :name
      t.text :description
      t.string :api_key
      t.string :claim_token
      t.string :verification_code
      t.string :status

      t.uuid :userid

      t.index :api_key, unique: true
      t.index :claim_token, unique: true
      t.index :userid, name: "index_agents_on_userid"

      t.timestamps
    end
  end
end
