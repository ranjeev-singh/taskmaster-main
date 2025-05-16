class Task < ApplicationRecord

  belongs_to :assigned_to, class_name: 'User', foreign_key: 'assigned_to_id'
  belongs_to :assigned_by, class_name: 'User', foreign_key: 'assigned_by_id'

  after_create :create_task_status_api_call
  after_update :update_task_status_api_call

  enum status: %w{pending in_progress completed}
  validates :title, :description, :due_date, presence: true
  scope :notify_pending_task, -> { (where('due_date > ? AND due_date <= ?', Date.today, Date.today + 25.days)) }

  def as_json(options = {})
    super(options.merge(
      include: {
        assigned_to: { only: [:id, :email] },
        assigned_by: { only: [:id, :email] }
      }
    ))
  end

  def create_task_status_api_call
    response = HTTParty.post("http://localhost:4001/api/v1/task_statuses", {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        task_status: {
          status: "pending",
          description: self.title,
          user_id: 1,
          update_date: Time.now
        }
      }.to_json
    })
  end

  def update_task_status_api_call
    response = HTTParty.put("http://localhost:4001/api/v1/task_statuses/1", {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        task_status: {
          status: self.status,
          description: self.title,
          update_date: Time.now
        }
      }.to_json
    })
  end
end
