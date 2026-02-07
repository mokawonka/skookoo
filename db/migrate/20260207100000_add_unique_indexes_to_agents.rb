# frozen_string_literal: true

class AddUniqueIndexesToAgents < ActiveRecord::Migration[7.2]
  def change
    add_index :agents, :api_key, unique: true
    add_index :agents, :claim_token, unique: true
  end
end
