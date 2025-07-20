ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  controller do
    before_action :authenticate_user!
    before_action :ensure_admin_access!

    private

    def authenticate_user!
      unless user_signed_in?
        redirect_to new_user_session_path, alert: "You must log in"
      end
    end

    def ensure_admin_access!
      unless current_user&.admin?
        redirect_to root_path, alert: "Unauthorized access"
      end
    end

    # Calculate comprehensive revenue statistics
    def calculate_revenue_stats
      confirmed_participations = Participation.where(status: :confirmed).joins(:event)
      current_month = Time.current.beginning_of_month..Time.current.end_of_month
      today = Time.current.beginning_of_day..Time.current.end_of_day

      {
        total_revenue: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
        monthly_revenue: confirmed_participations
          .where(created_at: current_month)
          .sum("events.price_cents * participations.seats") / 100.0,
        today_revenue: confirmed_participations
          .where(created_at: today)
          .sum("events.price_cents * participations.seats") / 100.0,
        average_transaction: calculate_average_transaction_value
      }
    end

    # Calculate event-related statistics
    def calculate_event_stats
      {
        total_events: Event.count,
        upcoming_events: Event.where(status: :upcoming).count,
        completed_events: Event.where(status: :completed).count,
        sold_out_events: Event.where(status: :sold_out).count,
        occupancy_rate: calculate_occupancy_rate,
        average_capacity: Event.average(:max_capacity).to_i
      }
    end

    # Calculate user engagement statistics
    def calculate_user_stats
      current_month = Time.current.beginning_of_month..Time.current.end_of_month

      {
        total_users: User.count,
        admin_users: User.where(role: :admin).count,
        creator_users: User.where(role: :creator).count,
        regular_users: User.where(role: :user).count,
        new_users_this_month: User.where(created_at: current_month).count,
        active_participants: User.joins(:participations)
                                .where(participations: { status: :confirmed })
                                .distinct.count
      }
    end

    # Calculate participation and booking statistics
    def calculate_participation_stats
      {
        total_participations: Participation.count,
        confirmed_participations: Participation.where(status: :confirmed).count,
        pending_participations: Participation.where(status: :pending).count,
        cancelled_participations: Participation.where(status: :cancelled).count,
        total_seats_booked: Participation.where(status: :confirmed).sum(:seats),
        conversion_rate: calculate_conversion_rate
      }
    end

    # Calculate movie validation statistics
    def calculate_movie_stats
      {
        total_movies: Movie.count,
        validated_movies: Movie.where(validation_status: :approved).count,
        pending_movies: Movie.where(validation_status: :pending).count,
        rejected_movies: Movie.where(validation_status: :rejected).count,
        movies_with_events: Movie.joins(:events).distinct.count
      }
    end

    # Calculate satisfaction and review metrics
    def calculate_satisfaction_stats
      reviews = Review.where.not(rating: nil)

      {
        average_rating: reviews.average(:rating).to_f.round(1),
        total_reviews: Review.count,
        five_star_reviews: Review.where(rating: 5).count,
        satisfaction_trend: calculate_satisfaction_trend
      }
    end

    # Get recent activity data
    def get_recent_activities
      {
        recent_movies: Movie.includes(:user).order(created_at: :desc).limit(8),
        recent_participations: Participation.includes(:user, :event)
                                          .order(created_at: :desc).limit(8),
        recent_reviews: Review.includes(:user, :movie, :event)
                             .order(created_at: :desc).limit(6),
        pending_validations: Movie.where(validation_status: :pending).count
      }
    end

    # Generate chart data for revenue evolution
    def revenue_chart_data
      (30.days.ago.to_date..Date.current).map do |date|
        daily_revenue = Participation.where(status: :confirmed)
                                   .where(created_at: date.beginning_of_day..date.end_of_day)
                                   .joins(:event)
                                   .sum("events.price_cents * participations.seats") / 100.0

        {
          date: date.strftime("%d/%m"),
          revenue: daily_revenue,
          formatted_revenue: number_to_currency(daily_revenue)
        }
      end
    end

    # Generate chart data for events status distribution
    def events_status_chart_data
      Event.group(:status).count.map do |status, count|
        percentage = (count.to_f / Event.count * 100).round(1)

        {
          status: status.humanize,
          count: count,
          percentage: "#{percentage}%",
          color: status_color(status)
        }
      end
    end

    # Generate popular movies data
    def popular_movies_data
      Movie.joins(events: :participations)
           .where(participations: { status: :confirmed })
           .group('movies.id', 'movies.title')
           .order('COUNT(participations.id) DESC')
           .limit(5)
           .count
    end

    # Helper methods for calculations
    def calculate_average_transaction_value
      confirmed_participations = Participation.where(status: :confirmed).joins(:event)
      return 0 if confirmed_participations.empty?

      total_revenue = confirmed_participations.sum("events.price_cents * participations.seats")
      (total_revenue / confirmed_participations.count.to_f / 100.0).round(2)
    end

    def calculate_occupancy_rate
      total_capacity = Event.sum(:max_capacity)
      total_bookings = Participation.where(status: :confirmed).sum(:seats)

      return 0 if total_capacity.zero?
      ((total_bookings.to_f / total_capacity) * 100).round(1)
    end

    def calculate_conversion_rate
      total_participations = Participation.count
      return 0 if total_participations.zero?

      confirmed_participations = Participation.where(status: :confirmed).count
      ((confirmed_participations.to_f / total_participations) * 100).round(1)
    end

    def calculate_satisfaction_trend
      current_month_avg = Review.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month)
                               .average(:rating).to_f
      last_month_avg = Review.where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month)
                            .average(:rating).to_f

      return 0 if last_month_avg.zero?
      ((current_month_avg - last_month_avg) / last_month_avg * 100).round(1)
    end

    def status_color(status)
      case status.to_s
      when 'upcoming' then '#2563eb'
      when 'completed' then '#22c55e'
      when 'sold_out' then '#f59e0b'
      when 'cancelled' then '#ef4444'
      else '#6b7280'
      end
    end
  end

  content title: "CinéRoom Dashboard" do
    # Use custom layout instead of default ActiveAdmin layout
    render 'admin/dashboard/index', layout: 'admin_custom'
  end
end
