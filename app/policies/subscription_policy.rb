class SubscriptionPolicy < ApplicationPolicy
  def create?
    user.admin?
  end

  def index?
    user.admin?
  end

  def show?
    user.admin? || record.user_id == user.id
  end
end
