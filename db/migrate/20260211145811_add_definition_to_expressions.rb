class AddDefinitionToExpressions < ActiveRecord::Migration[7.2]
  def change
    add_column :expressions, :definition, :string, limit: 1000
  end
end
