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
