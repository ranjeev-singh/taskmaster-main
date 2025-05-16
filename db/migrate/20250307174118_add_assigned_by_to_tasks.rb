class AddAssignedByToTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :tasks, :assigned_by_id, :integer
  end
end
