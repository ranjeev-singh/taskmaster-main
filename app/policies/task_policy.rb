class TaskPolicy < ApplicationPolicy

  def index?
    user.present?
  end

  def show?
    admin? || (manager? && record.assigned_to) ||(user? && record.assigned_to == user)
  end

  def create?
    admin? || manager?
  end

  def update?
    admin? || (manager? && record.assigned_to) ||(user? && record.assigned_to == user)
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin? || user&.manager?
        scope.all
      elsif user.present?
        scope.where(assigned_to_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def admin?
    user&.admin?
  end

  def manager?
    user&.manager?
  end

  def user?
    user&.user?
  end
end
