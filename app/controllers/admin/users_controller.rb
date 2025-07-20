class Admin::UsersController < Admin::BaseController
  def toggle_role
    @user = User.find(params[:id])

    new_role = case @user.role
    when 'user' then 'creator'
    when 'creator' then 'admin'
    when 'admin' then 'user'
    else 'user'
    end

    if @user.update(role: new_role)
      flash[:notice] = "Rôle utilisateur mis à jour: #{new_role.humanize}"
    else
      flash[:alert] = "Erreur lors de la mise à jour du rôle."
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: admin_users_path) }
      format.json { render json: { success: true, new_role: new_role } }
    end
  end
end
