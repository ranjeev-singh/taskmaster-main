class TaskChannel < ApplicationCable::Channel
  def subscribed
    # Stream notifications specific to the current user
    stream_from "tasks_#{current_user.id}"
  end

  def unsubscribed
  end

end