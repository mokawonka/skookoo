class CreateAgents < ActiveRecord::Migration[7.2]
  def change
    create_table :agents, id: :uuid do |t|
      t.string :name
      t.text :description
      t.string :api_key
      t.string :claim_token
      t.string :verification_code
      t.string :status

      t.timestamps
    end
  end
end
