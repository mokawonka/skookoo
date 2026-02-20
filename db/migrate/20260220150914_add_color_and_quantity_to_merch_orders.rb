class AddColorAndQuantityToMerchOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :merch_orders, :color, :string
    add_column :merch_orders, :quantity, :integer
  end
end
