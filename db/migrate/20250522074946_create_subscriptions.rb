class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.string :status
      t.string :stripe_subscription_id
      t.string :currency
      t.text :remarks

      t.timestamps
    end
  end
end
