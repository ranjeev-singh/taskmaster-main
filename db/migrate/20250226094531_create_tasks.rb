class CreateTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.integer :status, default: 0
      t.datetime :due_date
      t.integer :assigned_to_id

      t.timestamps
    end
  end
end
