class CreateEmailNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :email_notifications do |t|
      t.string :email
      t.string :subject
      t.text :body

      t.timestamps
    end
  end
end
