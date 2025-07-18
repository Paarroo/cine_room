class Admin::DashboardPolicy < Admin::ApplicationPolicy
  def index?
    user&.admin?
  end
end
