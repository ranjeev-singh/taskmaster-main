module Api
  module V1
    class TasksController < ApplicationController
      before_action :authenticate_user!
      before_action :set_task, only: [:show, :update, :destroy]
      # after_action :verify_authorized, except: :index
      # after_action :verify_policy_scoped, only: :index

      def index
        @tasks = policy_scope(Task).order(created_at: :desc)

        if params[:q].present?
          @tasks = @tasks.joins(:assigned_to).where('users.email ILIKE ?', "%#{params[:q]}%")
        end

        if params[:status].present?
          @tasks = @tasks.where(status: params[:status])
        end

        if params[:start_date].present? || params[:end_date].present?
          start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.new(2000, 1, 1)
          end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_day
          @tasks = @tasks.where(due_date: start_date..end_date)
        end

        # API call to 2nd Rails app to get task_status's list
        response = HTTParty.get("http://localhost:4001/api/v1/task_statuses")

        render json: @tasks
      end

      def show
        authorize @task
        # API call to 2nd Rails app to get task status details
        response = HTTParty.get("http://localhost:4001/api/v1/task_statuses/1", query: { description: @task.title })

        render json: @task
      end

      def create
        @task = Task.new(task_params)
        authorize @task
        @task.assigned_by = current_user
        if @task.save
          render json: @task, status: :created
          ActionCable.server.broadcast(
            "tasks_#{@task.assigned_to_id}",
            {
              action: 'task_assigned',
              task: task_response(@task),
              message: "Task '#{@task.title}' has been assigned to you by #{@task.assigned_by.email}"
            }
          )
          TaskMailer.assigned_task(@task).deliver_later
        else
          render json: @task.errors, status: :unprocessable_entity
        end
      end

      def update
        authorize @task
        if @task.update(update_params)
          render json: @task
          if current_user.user?
            ActionCable.server.broadcast(
              "tasks_#{@task.assigned_by_id}",
              {
                action: 'status_updated',
                task: task_response(@task),
                message: "The status of task chnage to '#{@task.status}' by #{@task.assigned_to.email}"
              }
            )
            TaskMailer.status_updated_notification(@task).deliver_later
          else
            ActionCable.server.broadcast(
              "tasks_#{@task.assigned_to_id}",
              {
                action: 'task_updated',
                task: task_response(@task),
                message: "Task updated by #{current_user.email}"
              }
            )
          end
        else
          render json: @task.errors, status: :unprocessable_entity
        end
        #for testing purpose if user is force at invalid status
        rescue ArgumentError => e
          @task.errors.add(:status, e.message)
          render json: @task.errors, status: :unprocessable_entity
      end

      def destroy
        authorize @task
        if @task.destroy

          # API call to 2nd Rails app to delete task_status
          response = HTTParty.delete("http://localhost:4001/api/v1/task_statuses/1", query: { description: @task.title })

          ActionCable.server.broadcast(
            "tasks_#{@task.assigned_to_id}",
            {
              action: 'deleted',
              task: task_response(@task),
              message: "The deleted by #{current_user.email}"
            }
          )
        end

        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:id])
      end

      def task_params
        params.require(:task).permit(:title, :description, :status, :due_date, :assigned_to_id, :assigned_by_id)
      end

      def update_params
        params.require(:task).permit(:title, :description, :status, :due_date)
      end

      def task_response(task)
        { id: task.id,
          title: task.title,
          description: task.description,
          status: task.status,
          due_date: task.due_date&.iso8601,
          assigned_to: { email: task.assigned_to&.email }
        }
      end

    end
  end
end