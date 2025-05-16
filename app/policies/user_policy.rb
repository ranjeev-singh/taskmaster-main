class UserPolicy < ApplicationPolicy

  def index?
    admin? || manager?
  end

  def show?
    admin? || manager?
  end

  def destroy?
    admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin? || user&.manager?
        scope.all
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
end