class UserManagementService
  def initialize(users_scope = nil)
    @users_scope = users_scope || User.all
  end

  def calculate_statistics
    {
      total: @users_scope.count,
      admins: @users_scope.where(role: :admin).count,
      creators: @users_scope.where(role: :creator).count,
      users: @users_scope.where(role: :user).count,
      active_this_month: calculate_active_users_this_month,
      new_this_month: @users_scope.where(created_at: 1.month.ago..Time.current).count,
      average_movies_per_user: calculate_average_movies_per_user,
      average_participations_per_user: calculate_average_participations_per_user
    }
  end

  def calculate_user_activity_summary(user)
    {
      total_movies: user.movies.count,
      total_participations: user.participations.count,
      total_reviews: user.reviews.count,
      last_login: user.last_sign_in_at,
      member_since: user.created_at,
      participation_rate: calculate_user_participation_rate(user),
      favorite_genres: calculate_user_favorite_genres(user)
    }
  end

  def calculate_profile_completion_status(user)
    fields = [:first_name, :last_name, :bio, :email]
    completed_fields = fields.count { |field| user.send(field).present? }
    completion_percentage = (completed_fields.to_f / fields.length * 100).round(1)
    
    {
      completion_percentage: completion_percentage,
      missing_fields: fields.reject { |field| user.send(field).present? },
      completed_fields: completed_fields,
      total_fields: fields.length
    }
  end

  def bulk_promote_users(user_ids)
    users = User.where(id: user_ids, role: :user)
    
    if users.empty?
      return { success: false, error: 'Aucun utilisateur éligible trouvé' }
    end

    promoted_count = 0
    users.find_each do |user|
      if user.update(role: :admin)
        promoted_count += 1
      end
    end

    {
      success: true,
      message: "#{promoted_count} utilisateurs promus administrateurs",
      count: promoted_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def bulk_demote_users(user_ids)
    users = User.where(id: user_ids, role: [:admin, :creator])
    
    if users.empty?
      return { success: false, error: 'Aucun utilisateur éligible trouvé' }
    end

    demoted_count = 0
    users.find_each do |user|
      if user.update(role: :user)
        demoted_count += 1
      end
    end

    {
      success: true,
      message: "#{demoted_count} utilisateurs rétrogradés",
      count: demoted_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def bulk_promote_to_creator(user_ids)
    users = User.where(id: user_ids, role: :user)
    
    if users.empty?
      return { success: false, error: 'Aucun utilisateur éligible trouvé' }
    end

    promoted_count = 0
    users.find_each do |user|
      if user.update(role: :creator)
        promoted_count += 1
      end
    end

    {
      success: true,
      message: "#{promoted_count} utilisateurs promus créateurs",
      count: promoted_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def toggle_user_role(user)
    new_role = case user.role
    when 'user' then 'creator'
    when 'creator' then 'admin'
    when 'admin' then 'user'
    else 'user'
    end

    user.update!(role: new_role)
    new_role
  end

  def promote_to_admin(user)
    user.update!(role: :admin)
  end

  def demote_to_user(user)
    user.update!(role: :user)
  end

  def reset_user_password(user)
    new_password = SecureRandom.alphanumeric(12)
    user.update!(password: new_password, password_confirmation: new_password)
    new_password
  end

  def export_data(users_scope)
    users_scope.includes(:movies, :participations, :reviews).map do |user|
      activity = calculate_user_activity_summary(user)
      profile = calculate_profile_completion_status(user)
      
      {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        role: user.role.humanize,
        total_movies: activity[:total_movies],
        total_participations: activity[:total_participations],
        total_reviews: activity[:total_reviews],
        profile_completion: "#{profile[:completion_percentage]}%",
        member_since: user.created_at.strftime('%d/%m/%Y'),
        last_login: user.last_sign_in_at&.strftime('%d/%m/%Y %H:%M') || 'Jamais',
        created_at: user.created_at.strftime('%d/%m/%Y %H:%M')
      }
    end
  end

  def get_filter_options
    {
      roles: User.roles.keys.map { |r| [r.humanize, r] },
      activity_levels: [
        ['Très actif (10+ participations)', 'very_active'],
        ['Actif (3-9 participations)', 'active'],
        ['Peu actif (1-2 participations)', 'low_active'],
        ['Inactif (0 participation)', 'inactive']
      ]
    }
  end

  def can_modify_user?(current_user, target_user)
    return true if current_user.admin?
    return false if target_user.admin?
    return false if target_user == current_user

    current_user.creator? && target_user.user?
  end

  private

  def calculate_active_users_this_month
    @users_scope.joins(:participations)
                .where(participations: { created_at: 1.month.ago..Time.current })
                .distinct
                .count
  end

  def calculate_average_movies_per_user
    total_movies = Movie.count
    total_users = @users_scope.count
    
    return 0 if total_users.zero?
    
    (total_movies.to_f / total_users).round(2)
  end

  def calculate_average_participations_per_user
    total_participations = Participation.count
    total_users = @users_scope.count
    
    return 0 if total_users.zero?
    
    (total_participations.to_f / total_users).round(2)
  end

  def calculate_user_participation_rate(user)
    total_events = Event.count
    user_participations = user.participations.count
    
    return 0 if total_events.zero?
    
    (user_participations.to_f / total_events * 100).round(1)
  end

  def calculate_user_favorite_genres(user)
    user.participations
        .joins(event: :movie)
        .group('movies.genre')
        .count
        .sort_by { |genre, count| -count }
        .first(3)
        .map { |genre, count| { genre: genre, count: count } }
  end
end