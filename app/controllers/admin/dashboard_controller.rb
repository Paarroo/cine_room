class Admin::DashboardController < Admin::BaseController
  def refresh
    metrics = {
      revenue: calculate_revenue_metrics,
      events: calculate_event_metrics,
      users: calculate_user_metrics,
      satisfaction: calculate_satisfaction_metrics
    }

    charts = {
      revenue: revenue_chart_data,
      events: events_status_chart_data
    }

    activities = get_recent_activities

    respond_to do |format|
      format.json do
        render json: {
          metrics: metrics,
          charts: charts,
          activities: activities,
          timestamp: Time.current.iso8601
        }
      end

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("metrics", partial: "admin/dashboard/metrics", locals: { metrics: metrics }),
          turbo_stream.replace("charts", partial: "admin/dashboard/charts", locals: { charts: charts }),
          turbo_stream.replace("activities", partial: "admin/dashboard/activities", locals: { activities: activities })
        ]
      end
    end
  end

  def quick_stats
    render json: {
      online_users: calculate_online_users,
      pending_items: calculate_pending_items,
      revenue_today: calculate_today_revenue,
      system_status: 'operational'
    }
  end

  def export
    type = params[:type] || 'all'

    case type
    when 'users'
      export_users_data
    when 'events'
      export_events_data
    when 'participations'
      export_participations_data
    else
      export_all_data
    end
  end

  private

  def calculate_revenue_metrics
    confirmed_participations = Participation.where(status: :confirmed).joins(:event)

    {
      total: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
      monthly: confirmed_participations
        .where(created_at: Time.current.beginning_of_month..Time.current.end_of_month)
        .sum("events.price_cents * participations.seats") / 100.0,
      daily: confirmed_participations
        .where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
        .sum("events.price_cents * participations.seats") / 100.0
    }
  end

  def calculate_event_metrics
    {
      total: Event.count,
      upcoming: Event.where(status: :upcoming).count,
      completed: Event.where(status: :completed).count,
      sold_out: Event.where(status: :sold_out).count
    }
  end

  def calculate_user_metrics
    {
      total: User.count,
      new_this_month: User.where(created_at: Time.current.beginning_of_month..Time.current.end_of_month).count,
      active: User.joins(:participations).where(participations: { status: :confirmed }).distinct.count
    }
  end

  def calculate_satisfaction_metrics
    {
      average: Review.average(:rating).to_f.round(1),
      total_reviews: Review.count,
      five_star: Review.where(rating: 5).count
    }
  end

  def revenue_chart_data
    (30.days.ago.to_date..Date.current).map do |date|
      revenue = Participation.where(status: :confirmed)
                           .where(created_at: date.beginning_of_day..date.end_of_day)
                           .joins(:event)
                           .sum("events.price_cents * participations.seats") / 100.0

      {
        date: date.strftime("%d/%m"),
        revenue: revenue,
        formatted_revenue: ActionController::Base.helpers.number_to_currency(revenue)
      }
    end
  end

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

  def get_recent_activities
    activities = []

    Participation.includes(:user, :event)
                 .order(created_at: :desc)
                 .limit(5)
                 .each do |participation|
      activities << {
        type: 'participation',
        title: 'Nouvelle réservation',
        description: "#{participation.user&.full_name} • #{participation.event&.title}",
        time_ago: ActionController::Base.helpers.time_ago_in_words(participation.created_at),
        icon: 'ticket-alt',
        color: 'primary'
      }
    end

    Movie.includes(:user)
         .order(created_at: :desc)
         .limit(3)
         .each do |movie|
      activities << {
        type: 'movie',
        title: 'Nouveau film ajouté',
        description: "\"#{movie.title}\" par #{movie.user&.full_name}",
        time_ago: ActionController::Base.helpers.time_ago_in_words(movie.created_at),
        icon: 'film',
        color: 'blue-400'
      }
    end

    activities.sort_by { |a| a[:time_ago] }.first(8)
  end

  def calculate_online_users
    User.where('updated_at > ?', 1.hour.ago).count
  end

  def calculate_pending_items
    Movie.where(validation_status: :pending).count +
    Participation.where(status: :pending).count
  end

  def calculate_today_revenue
    Participation.where(status: :confirmed)
                 .where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
                 .joins(:event)
                 .sum("events.price_cents * participations.seats") / 100.0
  end

  def export_users_data
    users_data = User.all.map do |user|
      {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        created_at: user.created_at,
        participations_count: user.participations.count,
        movies_count: user.movies.count
      }
    end

    send_data users_data.to_json,
              filename: "cineroom_users_#{Date.current}.json",
              type: 'application/json',
              disposition: 'attachment'
  end

  def export_events_data
    events_data = Event.includes(:movie, :participations).map do |event|
      {
        id: event.id,
        title: event.title,
        movie_title: event.movie&.title,
        venue_name: event.venue_name,
        event_date: event.event_date,
        max_capacity: event.max_capacity,
        bookings_count: event.participations.where(status: :confirmed).count,
        revenue: event.participations.where(status: :confirmed).sum(:seats) * event.price_cents / 100.0,
        status: event.status
      }
    end

    send_data events_data.to_json,
              filename: "cineroom_events_#{Date.current}.json",
              type: 'application/json',
              disposition: 'attachment'
  end

  def export_participations_data
    participations_data = Participation.includes(:user, :event).map do |participation|
      {
        id: participation.id,
        user_email: participation.user&.email,
        event_title: participation.event&.title,
        seats: participation.seats,
        status: participation.status,
        created_at: participation.created_at,
        total_amount: participation.seats * participation.event.price_cents / 100.0
      }
    end

    send_data participations_data.to_json,
              filename: "cineroom_participations_#{Date.current}.json",
              type: 'application/json',
              disposition: 'attachment'
  end

  def export_all_data
    all_data = {
      users: User.count,
      events: Event.count,
      participations: Participation.count,
      movies: Movie.count,
      total_revenue: Participation.where(status: :confirmed).joins(:event).sum("events.price_cents * participations.seats") / 100.0,
      exported_at: Time.current.iso8601
    }

    send_data all_data.to_json,
              filename: "cineroom_summary_#{Date.current}.json",
              type: 'application/json',
              disposition: 'attachment'
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
