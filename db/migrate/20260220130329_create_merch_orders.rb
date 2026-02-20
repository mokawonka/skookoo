class CreateMerchOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :merch_orders, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :highlight, null: false, foreign_key: true, type: :uuid
      t.string :product_type
      t.text :design_text
      t.string :status

      t.timestamps
    end
  end
end
