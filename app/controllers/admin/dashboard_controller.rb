class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_user

  layout 'admin'

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

  def ensure_admin_user
    redirect_to root_path unless current_user&.admin?
  end

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
