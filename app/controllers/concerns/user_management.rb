module UserManagement
  extend ActiveSupport::Concern

  # User role management actions
  def promote_to_admin_action(user)
    user.update!(role: :admin)
  end

  def demote_to_user_action(user)
    user.update!(role: :user)
  end

  def toggle_role_action(user)
    case user.role
    when 'user'
      user.update!(role: :creator)
    when 'creator'
      user.update!(role: :admin)
    when 'admin'
      user.update!(role: :user)
    end
  end

  # Bulk operations for multiple users
  def bulk_promote_users(user_ids)
    User.where(id: user_ids).update_all(
      role: :admin,
      updated_at: Time.current
    )
  end

  def bulk_demote_users(user_ids)
    User.where(id: user_ids).update_all(
      role: :user,
      updated_at: Time.current
    )
  end

  def bulk_promote_to_creator(user_ids)
    User.where(id: user_ids).update_all(
      role: :creator,
      updated_at: Time.current
    )
  end

  # Password management
  def reset_password_action(user)
    new_password = SecureRandom.hex(8)
    user.update!(
      password: new_password,
      password_confirmation: new_password
    )

    # Send email with new password (uncomment when ready)
    # UserMailer.password_reset(user, new_password).deliver_now

    new_password
  end

  # User statistics and metrics
  def calculate_user_stats
    {
      total: User.count,
      admins: User.where(role: :admin).count,
      creators: User.where(role: :creator).count,
      regular_users: User.where(role: :user).count,
      movie_creators: User.joins(:movies).distinct.count,
      active_users: User.joins(:participations)
                       .where(participations: { status: :confirmed })
                       .distinct.count
    }
  end

  # User filtering and search
  def filter_users(params)
    users = User.includes(:movies, :participations, :reviews)

    # Filter by role
    users = users.where(role: params[:role]) if params[:role].present?

    # Filter by creator status
    if params[:creator_status].present?
      case params[:creator_status]
      when 'with_movies'
        users = users.joins(:movies).distinct
      when 'without_movies'
        users = users.left_joins(:movies).where(movies: { id: nil })
      end
    end

    # Filter by activity level
    if params[:activity].present?
      case params[:activity]
      when 'active'
        users = users.joins(:participations)
                    .where(participations: { status: :confirmed })
                    .distinct
      when 'inactive'
        users = users.left_joins(:participations)
                    .where(participations: { id: nil })
      end
    end

    # Search by name or email
    if params[:q].present?
      users = users.where(
        "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
        "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"
      )
    end

    # Date range filter
    if params[:created_since].present?
      users = users.where(created_at: Date.parse(params[:created_since])..Time.current)
    end

    users.order(created_at: :desc)
  end

  # User profile completion check
  def profile_completion_status(user)
    fields = %w[first_name last_name bio]
    completed = fields.count { |field| user.send(field).present? }

    {
      percentage: (completed.to_f / fields.size * 100).round(1),
      completed_fields: completed,
      total_fields: fields.size,
      missing_fields: fields.reject { |field| user.send(field).present? }
    }
  end

  # User activity summary
  def user_activity_summary(user)
    {
      movies_created: user.movies.count,
      events_attended: user.participations.where(status: :confirmed).count,
      reviews_written: user.reviews.count,
      total_spent: user.participations
                      .joins(:event)
                      .where(status: :confirmed)
                      .sum("events.price_cents * participations.seats") / 100.0,
      last_activity: [
        user.movies.maximum(:created_at),
        user.participations.maximum(:created_at),
        user.reviews.maximum(:created_at)
      ].compact.max
    }
  end

  # Export user data for CSV/Excel
  def export_users_data(user_scope = User.all)
    user_scope.includes(:movies, :participations, :reviews)
              .limit(1000)
              .map do |user|
      activity = user_activity_summary(user)
      {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: user.full_name,
        role: user.role,
        movies_count: activity[:movies_created],
        participations_count: activity[:events_attended],
        reviews_count: activity[:reviews_written],
        total_spent: activity[:total_spent],
        created_at: user.created_at.strftime("%Y-%m-%d %H:%M:%S"),
        last_activity: activity[:last_activity]&.strftime("%Y-%m-%d %H:%M:%S")
      }
    end
  end

  # Get filter options for form selects
  def get_user_filter_options
    {
      roles: User.roles.keys.map { |role| [ role.humanize, role ] },
      creator_statuses: [
        [ 'All Users', '' ],
        [ 'With Movies', 'with_movies' ],
        [ 'Without Movies', 'without_movies' ]
      ],
      activity_levels: [
        [ 'All Users', '' ],
        [ 'Active (with bookings)', 'active' ],
        [ 'Inactive (no bookings)', 'inactive' ]
      ]
    }
  end

  private

  # Validate user permissions for sensitive operations
  def can_modify_user?(target_user)
    return true if current_user.admin?
    return false if target_user.admin?

    current_user.creator? && !target_user.creator?
  end

  # Log user management actions for audit trail
  def log_user_action(action, target_user, details = {})
    Rails.logger.info "User Management: #{current_user.email} #{action} user #{target_user.email} - #{details}"
  end
end
