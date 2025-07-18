class Admin::PagePolicy < Admin::ApplicationPolicy
  def show?
    user&.admin?
  end
end
