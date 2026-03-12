class AddOriginToExpressions < ActiveRecord::Migration[7.2]
  def change
    add_column :expressions, :origin, :string
  end
end
