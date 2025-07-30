class Admin::UsersController < Admin::ApplicationController
  include UserManagement

  before_action :set_user, only: [:show, :update, :toggle_role, :reset_password]

  def index
    @users_query = User.includes(:movies, :participations, :reviews)
    @users = filter_users(params).limit(50).to_a

    view_service = UserViewService.new
    view_data = view_service.prepare_index_data(@users)
    
    @stats = view_data[:stats]
    @filter_options = view_data[:filter_options]
  end

  def show
    view_service = UserViewService.new
    view_data = view_service.prepare_show_data(@user)
    
    @user_activity = view_data[:user_activity]
    @profile_completion = view_data[:profile_completion]
    @recent_movies = view_data[:recent_movies]
    @recent_participations = view_data[:recent_participations]
    @recent_reviews = view_data[:recent_reviews]
  end

  def update
    if @user.update(user_params)
      log_user_action('updated', @user, user_params.to_h)
      respond_to(&standard_success_response('Utilisateur mis à jour'))
    else
      respond_to(&standard_error_response(@user.errors))
    end
  end

  def toggle_role
    service = UserManagementService.new
    return unless service.can_modify_user?(current_user, @user)

    old_role = @user.role
    new_role = service.toggle_user_role(@user)
    log_user_action('role_changed', @user, { from: old_role, to: new_role })
    respond_to(&role_change_success_response(new_role))
  rescue StandardError => e
    respond_to(&error_response(e, 'du changement de rôle'))
  end

  def promote_to_admin
    service = UserManagementService.new
    return unless service.can_modify_user?(current_user, @user)

    service.promote_to_admin(@user)
    log_user_action('promoted_to_admin', @user)
    respond_to(&standard_success_response('Utilisateur promu administrateur'))
  rescue StandardError => e
    respond_to(&error_response(e, 'de la promotion'))
  end

  def demote_to_user
    service = UserManagementService.new
    return unless service.can_modify_user?(current_user, @user)

    service.demote_to_user(@user)
    log_user_action('demoted_to_user', @user)
    respond_to(&demote_success_response)
  rescue StandardError => e
    respond_to(&error_response(e, 'de la rétrogradation'))
  end

  def reset_password
    service = UserManagementService.new
    return unless service.can_modify_user?(current_user, @user)

    new_password = service.reset_user_password(@user)
    log_user_action('password_reset', @user)
    respond_to(&password_reset_success_response(new_password))
  rescue StandardError => e
    respond_to(&error_response(e, 'de la réinitialisation'))
  end

  def bulk_promote
    user_ids = params[:user_ids]
    return redirect_to admin_users_path, alert: 'Aucun utilisateur sélectionné' if user_ids.blank?

    view_service = UserViewService.new
    permission_check = view_service.check_bulk_permissions(current_user, user_ids)
    
    if permission_check[:error]
      return redirect_to admin_users_path, alert: permission_check[:error]
    end

    result = permission_check[:service].bulk_promote_users(user_ids)
    log_user_action('bulk_promoted', nil, { count: user_ids.count, ids: user_ids })
    respond_to(&bulk_operation_response(result))
  end

  def bulk_demote
    user_ids = params[:user_ids]
    return redirect_to admin_users_path, alert: 'Aucun utilisateur sélectionné' if user_ids.blank?

    view_service = UserViewService.new
    permission_check = view_service.check_bulk_permissions(current_user, user_ids)
    
    if permission_check[:error]
      return redirect_to admin_users_path, alert: permission_check[:error]
    end

    result = permission_check[:service].bulk_demote_users(user_ids)
    log_user_action('bulk_demoted', nil, { count: user_ids.count, ids: user_ids })
    respond_to(&bulk_operation_response(result))
  end

  def bulk_promote_to_creator
    user_ids = params[:user_ids]
    return redirect_to admin_users_path, alert: 'Aucun utilisateur sélectionné' if user_ids.blank?

    service = UserManagementService.new
    result = service.bulk_promote_to_creator(user_ids)
    log_user_action('bulk_promoted_to_creator', nil, { count: user_ids.count, ids: user_ids })
    respond_to(&bulk_operation_response(result))
  end

  def export
    users_scope = filter_users(params)
    view_service = UserViewService.new
    export_data = view_service.prepare_export_data(users_scope)
    filename = "users_export_#{Date.current.strftime('%Y%m%d')}.csv"

    respond_to do |format|
      format.json { render json: { success: true, data: export_data, filename: filename } }
      format.csv { send_data generate_csv(export_data), filename: filename }
    end
  rescue StandardError => e
    respond_to(&export_error_response(e))
  end

  def stats
    view_service = UserViewService.new
    stats_data = view_service.prepare_stats_data
    respond_to(&stats_response(stats_data))
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :role, :bio, :password, :password_confirmation)
  end

  def log_user_action(action, target_user, details = {})
    Rails.logger.info "Admin User Management: #{current_user.email} #{action} #{target_user&.email || 'multiple users'} - #{details}"
  end

  def generate_csv(data)
    return '' if data.empty?
    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  # Response helpers
  def standard_success_response(message)
    proc do |format|
      format.json { render json: { status: 'success', message: message } }
      format.html { redirect_to admin_user_path(@user), notice: "#{message} avec succès" }
    end
  end

  def standard_error_response(errors)
    proc do |format|
      format.json { render json: { status: 'error', errors: errors } }
      format.html { render :show, alert: 'Erreur lors de la mise à jour' }
    end
  end

  def error_response(error, action_name)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to admin_user_path(@user), alert: "Erreur lors #{action_name}" }
    end
  end

  def role_change_success_response(new_role)
    proc do |format|
      format.json { render json: { status: 'success', new_role: new_role.humanize } }
      format.html { redirect_to admin_user_path(@user), notice: "Rôle changé vers #{new_role.humanize}" }
    end
  end

  def demote_success_response
    proc do |format|
      format.json { render json: { status: 'success', message: 'Utilisateur rétrogradé' } }
      format.html { redirect_to admin_user_path(@user), notice: 'Utilisateur rétrogradé vers utilisateur standard' }
    end
  end

  def password_reset_success_response(new_password)
    proc do |format|
      format.json { render json: { status: 'success', message: 'Mot de passe réinitialisé', new_password: new_password } }
      format.html { redirect_to admin_user_path(@user), notice: "Mot de passe réinitialisé. Nouveau mot de passe: #{new_password}" }
    end
  end

  def bulk_operation_response(result)
    proc do |format|
      if result[:success]
        format.json { render json: { status: 'success', message: result[:message] } }
        format.html { redirect_to admin_users_path, notice: result[:message] }
      else
        format.json { render json: { status: 'error', message: result[:error] } }
        format.html { redirect_to admin_users_path, alert: result[:error] }
      end
    end
  end

  def export_error_response(error)
    proc do |format|
      format.json { render json: { status: 'error', message: error.message } }
      format.html { redirect_to admin_users_path, alert: 'Erreur lors de l\'export' }
    end
  end

  def stats_response(data)
    proc do |format|
      format.json { render json: data }
    end
  end
end