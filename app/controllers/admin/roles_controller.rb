class Admin::RolesController < Admin::ApplicationController
  before_action :set_user, only: [:show, :update]

  def show
    # Display user role information
    respond_to do |format|
      format.json do
        render json: {
          user_id: @user.id,
          current_role: @user.role,
          available_roles: available_roles_for_user(@user)
        }
      end
    end
  end

  def update
    return unless can_modify_user?(@user)

    new_role = params[:role]
    
    unless valid_role?(new_role)
      return redirect_to admin_user_path(@user), alert: 'Rôle invalide'
    end

    unless can_assign_role?(new_role)
      return redirect_to admin_user_path(@user), alert: 'Vous n\'avez pas les permissions pour ce rôle'
    end

    old_role = @user.role
    
    if @user.update(role: new_role)
      log_role_change(old_role, new_role)
      redirect_to admin_user_path(@user), notice: "Rôle mis à jour vers #{new_role.humanize}"
    else
      redirect_to admin_user_path(@user), alert: 'Erreur lors de la mise à jour du rôle'
    end
  rescue StandardError => e
    Rails.logger.error "Role update error: #{e.message}"
    redirect_to admin_user_path(@user), alert: 'Erreur lors du changement de rôle'
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def valid_role?(role)
    %w[user creator admin].include?(role)
  end

  def can_assign_role?(role)
    return true if current_user.admin?
    return false if role == 'admin' # Only admins can promote to admin
    return false if @user.admin? # Only admins can modify admin users
    
    current_user.creator? && role != 'admin'
  end

  def available_roles_for_user(user)
    if current_user.admin?
      %w[user creator admin] - [user.role]
    elsif current_user.creator?
      %w[user creator] - [user.role]
    else
      []
    end
  end

  def can_modify_user?(target_user)
    return true if current_user.admin?
    return false if target_user.admin?
    return false if target_user == current_user # Cannot modify own role
    
    current_user.creator? && target_user.user?
  end

  def log_role_change(old_role, new_role)
    Rails.logger.info "Admin Role Change: #{current_user.email} changed #{@user.email} from #{old_role} to #{new_role}"
    
    # Optional: create audit log
    # AuditLog.create(
    #   admin_user: current_user,
    #   action: 'role_changed',
    #   target_user: @user,
    #   details: { from: old_role, to: new_role },
    #   ip_address: request.remote_ip,
    #   user_agent: request.user_agent
    # )
  end
end