class DashboardAnalyticsService
  def initialize
  end

  def calculate_metrics
    {
      total_revenue: Participation.calculate_total_revenue,
      upcoming_events: Event.where(status: :upcoming).count,
      total_users: User.count,
      satisfaction: (Review.average(:rating) || 0).round(1)
    }
  end

  def revenue_chart_data
    Participation.revenue_chart_data
  end

  def events_status_chart_data  
    Event.events_status_chart_data
  end

  def quick_stats
    {
      pending_movies: Movie.where(validation_status: :pending).count,
      upcoming_events: Event.where(status: :upcoming).count,
      total_users: User.count,
      pending_participations: Participation.where(status: :pending).count
    }
  end

  def export_users_data
    User.export_data
  end

  def export_events_data
    Event.includes(:movie)
         .select(:id, :title, :venue_name, :event_date, :max_capacity, :status)
         .limit(1000)
         .map(&:attributes)
  end

  def export_movies_data
    Movie.export_data
  end

  def export_participations_data
    Participation.includes(:user, :event)
                 .select(:id, :user_id, :event_id, :seats, :status, :created_at)
                 .limit(1000)
                 .map(&:attributes)
  end
end