class SubscriptionPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def cancel_subscription?
    user.user? && record&.user_id == user.id
  end
end
