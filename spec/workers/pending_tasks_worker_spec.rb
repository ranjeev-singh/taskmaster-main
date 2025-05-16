require 'rails_helper'

RSpec.describe PendingTasksWorker, type: :worker do
  include ActiveJob::TestHelper

  it 'sends emails for pending tasks with approaching due dates' do
    admin = create(:user, :admin)
    user = create(:user)
    puts "Date: #{Faker::Date.forward(days: 4)}"
    task = create(:task, assigned_to: user, status: 'pending', due_date: Faker::Date.forward(days: 4), assigned_by: admin)
    expect(TaskMailer).to receive(:pending_tasks_notification).with(task).and_return(double(deliver_later: true))
    perform_enqueued_jobs do
      PendingTasksWorker.new.perform
    end
  end

  it 'does not send emails for completed tasks' do
    admin = create(:user, :admin)
    user = create(:user)
    create(:task, assigned_to: user, status: 'in_progress', due_date: Faker::Date.forward(days: 2), assigned_by: admin)
    expect(TaskMailer).not_to receive(:pending_tasks_notification)
    perform_enqueued_jobs do
      PendingTasksWorker.new.perform
    end
  end

  it 'does not send emails for completed tasks' do
    admin = create(:user, :admin)
    user = create(:user)
    create(:task, assigned_to: user, status: 'completed', due_date: Faker::Date.forward(days: 2), assigned_by: admin)
    expect(TaskMailer).not_to receive(:pending_tasks_notification)
    perform_enqueued_jobs do
      PendingTasksWorker.new.perform
    end
  end
end