class PendingTasksWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'mailers'

  def perform
    Task.pending.notify_pending_task.each do |task|
      if task.present?
        TaskMailer.pending_tasks_notification(task).deliver_later
      end
    end
  end
end