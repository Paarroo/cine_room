class Admin::DashboardController < ActiveAdmin::BaseController
  # No need for authentication - ActiveAdmin handles it

  def index
    @revenue_stats = calculate_revenue_stats
    @event_stats = calculate_event_stats
    @user_stats = calculate_user_stats
    @participation_stats = calculate_participation_stats
    @movie_stats = calculate_movie_stats

    @recent_movies = Movie.includes(:user).order(created_at: :desc).limit(5)
    @recent_events = Event.includes(:movie).order(created_at: :desc).limit(5)
    @recent_participations = Participation.includes(:user, :event)
                                         .order(created_at: :desc).limit(5)
    @recent_reviews = Review.includes(:user, :movie).order(created_at: :desc).limit(5)

    @pending_movies_count = Movie.where(validation_status: :pending).count
    @upcoming_events_count = Event.where(status: :upcoming).count
    @pending_participations_count = Participation.where(status: :pending).count

    respond_to do |format|
      format.html
      format.json { render json: dashboard_json_data }
    end
  end

  def refresh
    # Handle AJAX refresh requests
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("metrics", partial: "shared/admin/dashboard/metrics",
                              locals: { revenue_stats: calculate_revenue_stats }),
          turbo_stream.replace("recent-activity", partial: "shared/admin/dashboard/recent_activity")
        ]
      end
      format.json { render json: dashboard_json_data }
    end
  end

  def quick_stats
    render json: {
      online_users: calculate_online_users,
      pending_items: calculate_pending_items,
      revenue_today: calculate_today_revenue
    }
  end

  def export
    type = params[:type] || 'all'

    case type
    when 'users'
      export_users
    when 'events'
      export_events
    when 'participations'
      export_participations
    else
      export_all_data
    end
  end

  private

  def calculate_revenue_stats
    confirmed_participations = Participation.where(status: :confirmed).joins(:event)

    {
      total_revenue: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
      monthly_revenue: confirmed_participations
        .where(created_at: Time.current.beginning_of_month..Time.current.end_of_month)
        .sum("events.price_cents * participations.seats") / 100.0,
      average_event_price: Event.average(:price_cents).to_f / 100.0,
      average_revenue_per_event: calculate_average_revenue_per_event
    }
  end

  def calculate_event_stats
    {
      total_events: Event.count,
      upcoming_events: Event.where(status: :upcoming).count,
      completed_events: Event.where(status: :completed).count,
      sold_out_events: Event.where(status: :sold_out).count,
      average_capacity: Event.average(:max_capacity).to_i,
      occupancy_rate: calculate_occupancy_rate
    }
  end

  def calculate_user_stats
    {
      total_users: User.count,
      admin_users: User.where(role: :admin).count,
      regular_users: User.where(role: :user).count,
      creator_users: User.where(role: :creator).count,
      new_users_this_month: User.where(
        created_at: Time.current.beginning_of_month..Time.current.end_of_month
      ).count,
      active_participants: User.joins(:participations)
                              .where(participations: { status: :confirmed })
                              .distinct.count
    }
  end

  def calculate_participation_stats
    {
      total_participations: Participation.count,
      confirmed_participations: Participation.where(status: :confirmed).count,
      pending_participations: Participation.where(status: :pending).count,
      cancelled_participations: Participation.where(status: :cancelled).count,
      total_seats_booked: Participation.where(status: :confirmed).sum(:seats),
      average_seats_per_booking: Participation.average(:seats).to_f.round(1)
    }
  end

  def calculate_movie_stats
    {
      total_movies: Movie.count,
      validated_movies: Movie.where(validation_status: :validated).count,
      pending_movies: Movie.where(validation_status: :pending).count,
      rejected_movies: Movie.where(validation_status: :rejected).count,
      movies_with_events: Movie.joins(:events).distinct.count,
      average_movies_per_creator: calculate_average_movies_per_creator
    }
  end

  def calculate_average_revenue_per_event
    events_with_revenue = Event.joins(:participations)
                              .where(participations: { status: :confirmed })
                              .group(:id)
                              .sum("events.price_cents * participations.seats")

    return 0 if events_with_revenue.empty?

    events_with_revenue.values.sum / events_with_revenue.count.to_f / 100.0
  end

  def calculate_occupancy_rate
    total_capacity = Event.sum(:max_capacity)
    total_bookings = Participation.where(status: :confirmed).sum(:seats)

    return 0 if total_capacity.zero?

    ((total_bookings.to_f / total_capacity) * 100).round(1)
  end

  def calculate_average_movies_per_creator
    total_creators = User.where(role: :creator).count
    total_movies = Movie.count

    return 0 if total_creators.zero?

    (total_movies.to_f / total_creators).round(1)
  end

  def dashboard_json_data
    {
      revenue_stats: @revenue_stats,
      event_stats: @event_stats,
      user_stats: @user_stats,
      participation_stats: @participation_stats,
      movie_stats: @movie_stats,
      charts: {
        revenue: revenue_chart_data,
        events: events_status_chart_data
      }
    }
  end

  def revenue_chart_data
    # Last 30 days revenue data for charts
    (30.days.ago.to_date..Date.current).map do |date|
      revenue = Participation.where(status: :confirmed)
                            .where(created_at: date.beginning_of_day..date.end_of_day)
                            .joins(:event)
                            .sum("events.price_cents * participations.seats") / 100.0

      { date: date.strftime("%d/%m"), revenue: revenue }
    end
  end

  def events_status_chart_data
    Event.group(:status).count.map do |status, count|
      { status: status.humanize, count: count }
    end
  end
end
