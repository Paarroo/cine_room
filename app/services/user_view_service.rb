class UserViewService
  def initialize
  end

  def prepare_index_data(users)
    service = UserManagementService.new(User.all)
    
    {
      stats: service.calculate_statistics,
      filter_options: service.get_filter_options
    }
  end

  def prepare_show_data(user)
    service = UserManagementService.new
    
    {
      user_activity: service.calculate_user_activity_summary(user),
      profile_completion: service.calculate_profile_completion_status(user),
      recent_movies: user.movies.order(created_at: :desc).limit(5),
      recent_participations: find_recent_participations(user),
      recent_reviews: find_recent_reviews(user)
    }
  end

  def prepare_stats_data
    service = UserManagementService.new
    {
      stats: service.calculate_statistics,
      recent_signups: User.where(created_at: 1.week.ago..Time.current).count,
      active_this_month: User.joins(:participations)
                             .where(participations: { created_at: 1.month.ago..Time.current })
                             .distinct.count
    }
  end

  def prepare_export_data(users_scope)
    service = UserManagementService.new
    service.export_data(users_scope)
  end

  def check_bulk_permissions(current_user, user_ids)
    service = UserManagementService.new
    users = User.where(id: user_ids)
    
    return { error: 'Utilisateurs non trouvés', users: [] } if users.empty?
    
    unauthorized_users = users.reject { |user| service.can_modify_user?(current_user, user) }
    
    if unauthorized_users.any?
      return { 
        error: "Vous n'avez pas les permissions pour modifier certains utilisateurs",
        users: []
      }
    end
    
    { users: users, service: service }
  end

  private

  def find_recent_participations(user)
    user.participations
        .includes(:event)
        .order(created_at: :desc)
        .limit(10)
  end

  def find_recent_reviews(user)
    user.reviews
        .includes(:movie, :event)
        .order(created_at: :desc)
        .limit(10)
  end
end