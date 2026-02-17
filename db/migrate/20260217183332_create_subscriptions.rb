class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :plan
      t.integer :status
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.datetime :current_period_end

      t.timestamps
    end
  end
end
