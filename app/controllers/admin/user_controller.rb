class Admin::UsersController < Admin::ApplicationController
  include UserManagement

  before_action :set_user, only: [:show, :update, :toggle_role, :reset_password]

  def index
    @users_query = User.includes(:movies, :participations, :reviews)

    # Apply filters using concern method
    @users = filter_users(params).limit(50).to_a

    # Calculate stats using concern method
    @stats = calculate_user_stats

    # Get filter options for form
    @filter_options = get_user_filter_options
  end

  def show
    @user_activity = user_activity_summary(@user)
    @profile_completion = profile_completion_status(@user)
    @recent_movies = @user.movies.order(created_at: :desc).limit(5)
    @recent_participations = @user.participations
                                  .includes(:event)
                                  .order(created_at: :desc)
                                  .limit(10)
    @recent_reviews = @user.reviews
                           .includes(:movie, :event)
                           .order(created_at: :desc)
                           .limit(10)
  end

  def update
    if @user.update(user_params)
      log_user_action('updated', @user, user_params.to_h)

      respond_to do |format|
        format.json { render json: { status: 'success', message: 'Utilisateur mis à jour' } }
        format.html { redirect_to admin_user_path(@user), notice: 'Utilisateur mis à jour avec succès' }
      end
    else
      respond_to do |format|
        format.json { render json: { status: 'error', errors: @user.errors } }
        format.html { render :show, alert: 'Erreur lors de la mise à jour' }
      end
    end
  end

  # Role management actions
  def toggle_role
    return unless can_modify_user?(@user)

    old_role = @user.role
    toggle_role_action(@user)
    log_user_action('role_changed', @user, { from: old_role, to: @user.role })

    respond_to do |format|
      format.json { render json: { status: 'success', new_role: @user.role.humanize } }
      format.html { redirect_to admin_user_path(@user), notice: "Rôle changé vers #{@user.role.humanize}" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_user_path(@user), alert: 'Erreur lors du changement de rôle' }
    end
  end

  def promote_to_admin
    return unless can_modify_user?(@user)

    promote_to_admin_action(@user)
    log_user_action('promoted_to_admin', @user)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Utilisateur promu administrateur' } }
      format.html { redirect_to admin_user_path(@user), notice: 'Utilisateur promu administrateur' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_user_path(@user), alert: 'Erreur lors de la promotion' }
    end
  end

  def demote_to_user
    return unless can_modify_user?(@user)

    demote_to_user_action(@user)
    log_user_action('demoted_to_user', @user)

    respond_to do |format|
      format.json { render json: { status: 'success', message: 'Utilisateur rétrogradé' } }
      format.html { redirect_to admin_user_path(@user), notice: 'Utilisateur rétrogradé vers utilisateur standard' }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_user_path(@user), alert: 'Erreur lors de la rétrogradation' }
    end
  end

  def reset_password
    return unless can_modify_user?(@user)

    new_password = reset_password_action(@user)
    log_user_action('password_reset', @user)

    respond_to do |format|
      format.json do
        render json: {
          status: 'success',
          message: 'Mot de passe réinitialisé',
          new_password: new_password
        }
      end
      format.html do
        redirect_to admin_user_path(@user),
                    notice: "Mot de passe réinitialisé. Nouveau mot de passe: #{new_password}"
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_user_path(@user), alert: 'Erreur lors de la réinitialisation' }
    end
  end

  # Bulk operations
  def bulk_promote
    user_ids = params[:user_ids]
    return redirect_to admin_users_path, alert: 'Aucun utilisateur sélectionné' if user_ids.blank?

    users_to_promote = User.where(id: user_ids)
    return redirect_to admin_users_path, alert: 'Utilisateurs non trouvés' if users_to_promote.empty?

    # Check permissions for each user
    unauthorized_users = users_to_promote.reject { |user| can_modify_user?(user) }
    if unauthorized_users.any?
      return redirect_to admin_users_path,
                        alert: "Vous n'avez pas les permissions pour modifier certains utilisateurs"
    end

    bulk_promote_users(user_ids)
    log_user_action('bulk_promoted', nil, { count: user_ids.count, ids: user_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{user_ids.count} utilisateurs promus" } }
      format.html { redirect_to admin_users_path, notice: "#{user_ids.count} utilisateurs promus administrateurs" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_users_path, alert: 'Erreur lors de la promotion en masse' }
    end
  end

  def bulk_demote
    user_ids = params[:user_ids]
    return redirect_to admin_users_path, alert: 'Aucun utilisateur sélectionné' if user_ids.blank?

    users_to_demote = User.where(id: user_ids)
    return redirect_to admin_users_path, alert: 'Utilisateurs non trouvés' if users_to_demote.empty?

    # Check permissions
    unauthorized_users = users_to_demote.reject { |user| can_modify_user?(user) }
    if unauthorized_users.any?
      return redirect_to admin_users_path,
                        alert: "Vous n'avez pas les permissions pour modifier certains utilisateurs"
    end

    bulk_demote_users(user_ids)
    log_user_action('bulk_demoted', nil, { count: user_ids.count, ids: user_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{user_ids.count} utilisateurs rétrogradés" } }
      format.html { redirect_to admin_users_path, notice: "#{user_ids.count} utilisateurs rétrogradés" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_users_path, alert: 'Erreur lors de la rétrogradation en masse' }
    end
  end

  def bulk_promote_to_creator
    user_ids = params[:user_ids]
    return redirect_to admin_users_path, alert: 'Aucun utilisateur sélectionné' if user_ids.blank?

    bulk_promote_to_creator(user_ids)
    log_user_action('bulk_promoted_to_creator', nil, { count: user_ids.count, ids: user_ids })

    respond_to do |format|
      format.json { render json: { status: 'success', message: "#{user_ids.count} utilisateurs promus créateurs" } }
      format.html { redirect_to admin_users_path, notice: "#{user_ids.count} utilisateurs promus créateurs" }
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_users_path, alert: 'Erreur lors de la promotion en masse' }
    end
  end

  # Export functionality
  def export
    users_scope = filter_users(params)
    @export_data = export_users_data(users_scope)

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          data: @export_data,
          filename: "users_export_#{Date.current.strftime('%Y%m%d')}.csv"
        }
      end
      format.csv do
        send_data generate_csv(@export_data),
                  filename: "users_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.json { render json: { status: 'error', message: e.message } }
      format.html { redirect_to admin_users_path, alert: 'Erreur lors de l\'export' }
    end
  end

  # Statistics endpoint
  def stats
    respond_to do |format|
      format.json do
        render json: {
          stats: calculate_user_stats,
          recent_signups: User.where(created_at: 1.week.ago..Time.current).count,
          active_this_month: User.joins(:participations)
                                 .where(participations: { created_at: 1.month.ago..Time.current })
                                 .distinct.count
        }
      end
    end
  end
