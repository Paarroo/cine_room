class Admin::ApplicationController < ApplicationController
  before_action :ensure_admin!

  layout 'admin'

  private

  def ensure_admin!
    unless user_signed_in? && current_user.admin?

      redirect_to admin_login_path, alert: "Accès non autorisé. Seuls les administrateurs peuvent accéder à cette zone."
    end
  end
end
