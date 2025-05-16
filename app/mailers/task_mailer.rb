class TaskMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def pending_tasks_notification(task)
    @task = task
    @user = task.assigned_to
    mail(to: @user.email, subject: "Reminder: '#{@task.title}' is Still Pending")
  end

  def assigned_task(task)
    @task = task
    @user = task.assigned_to
    @assignee = task.assigned_by
    mail(to: @user.email, subject: "New Task Assigned: '#{@task.title}'")
  end

   def status_updated_notification(task)
    @task = task
    @user = task.assigned_to
    @assignee = task.assigned_by
    mail(to: @assignee.email, subject: "Task '#{@task.title}' Status Updated by #{@user.email}")
  end

end
