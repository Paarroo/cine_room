module Admin::DashboardHelper
  def revenue_chart_data
    @revenue_chart_data ||= begin
      (30.days.ago.to_date..Date.current).map do |date|
        revenue = Participation.where(status: :confirmed)
                              .where(created_at: date.beginning_of_day..date.end_of_day)
                              .joins(:event)
                              .sum("events.price_cents * participations.seats") / 100.0

        {
          date: date.strftime("%d/%m"),
          revenue: revenue,
          formatted_revenue: number_to_currency(revenue)
        }
      end
    end
  end

  # Generate events status chart data
  def events_status_chart_data
    @events_status_chart_data ||= begin
      status_counts = Event.group(:status).count
      total_events = status_counts.values.sum

      status_counts.map do |status, count|
        {
          status: status.humanize,
          count: count,
          percentage: total_events.zero? ? 0 : ((count.to_f / total_events) * 100).round(1),
          color: status_color(status)
        }
      end
    end
  end

  # Calculate percentage change between two values
  def percentage_change(current, previous)
    return 0 if previous.zero?

    change = ((current - previous).to_f / previous) * 100
    change.round(1)
  end

  # Format trend indicator with appropriate styling
  def trend_indicator(current, previous, format: :percentage)
    change = case format
    when :percentage
               percentage_change(current, previous)
    when :absolute
               current - previous
    else
               current - previous
    end

    trend_type = change.positive? ? 'positive' : change.negative? ? 'negative' : 'neutral'

    {
      value: format == :percentage ? "#{change > 0 ? '+' : ''}#{change}%" : "#{change > 0 ? '+' : ''}#{change}",
      type: trend_type,
      class: trend_class(trend_type)
    }
  end

  # Get CSS classes for trend indicators
  def trend_class(trend_type)
    case trend_type
    when 'positive'
      'text-green-400 bg-green-400/10'
    when 'negative'
      'text-red-400 bg-red-400/10'
    else
      'text-gray-400 bg-gray-400/10'
    end
  end

  # Calculate occupancy rate for a specific period
  def calculate_occupancy_rate(start_date = nil, end_date = nil)
    events_scope = Event.all
    events_scope = events_scope.where(event_date: start_date..end_date) if start_date && end_date

    total_capacity = events_scope.sum(:max_capacity)
    return 0 if total_capacity.zero?

    participation_scope = Participation.where(status: :confirmed).joins(:event)
    participation_scope = participation_scope.where(events: { event_date: start_date..end_date }) if start_date && end_date

    total_bookings = participation_scope.sum(:seats)

    ((total_bookings.to_f / total_capacity) * 100).round(1)
  end

  # Get top performing events by revenue
  def top_events_by_revenue(limit = 5)
    Event.joins(:participations)
         .where(participations: { status: :confirmed })
         .group('events.id')
         .select('events.*, SUM(events.price_cents * participations.seats) as total_revenue_cents')
         .order('total_revenue_cents DESC')
         .limit(limit)
         .map do |event|
           {
             event: event,
             revenue: event.total_revenue_cents.to_i / 100.0,
             formatted_revenue: number_to_currency(event.total_revenue_cents.to_i / 100.0)
           }
         end
  end

  # Get conversion rate (visitors to participants)
  def conversion_rate
    total_users = User.count
    participants = User.joins(:participations).distinct.count

    return 0 if total_users.zero?

    ((participants.to_f / total_users) * 100).round(1)
  end

  # Format large numbers for display
  def format_large_number(number)
    case number
    when 0...1_000
      number.to_s
    when 1_000...1_000_000
      "#{(number / 1_000.0).round(1)}k"
    when 1_000_000...1_000_000_000
      "#{(number / 1_000_000.0).round(1)}M"
    else
      "#{(number / 1_000_000_000.0).round(1)}B"
    end
  end

  # Get dashboard refresh timestamp
  def dashboard_last_updated
    Time.current.strftime("%H:%M:%S")
  end

  # Check if there are critical alerts
  def has_critical_alerts?
    pending_movies_count > 10 ||
    pending_participations_count > 20 ||
    system_errors_count > 0
  end

  # Get system health status
  def system_health_status
    if has_critical_alerts?
      { status: 'warning', message: 'Attention requise', color: 'text-warning' }
    else
      { status: 'healthy', message: 'Système opérationnel', color: 'text-success' }
    end
  end

  # Status-specific colors for charts and indicators
  def status_color(status)
    case status.to_s
    when 'upcoming'
      '#2563eb' # Blue
    when 'completed'
      '#22c55e' # Green
    when 'sold_out'
      '#f59e0b' # Gold/Orange
    when 'cancelled'
      '#ef4444' # Red
    else
      '#6b7280' # Gray
    end
  end

  # Activity icon mapping
  def activity_icon(type)
    case type.to_s
    when 'participation'
      'ticket-alt'
    when 'movie'
      'film'
    when 'user'
      'user-plus'
    when 'review'
      'star'
    when 'event'
      'calendar-alt'
    else
      'bell'
    end
  end

  # Activity color mapping
  def activity_color(type)
    case type.to_s
    when 'participation'
      'primary'
    when 'movie'
      'blue-400'
    when 'user'
      'green-400'
    when 'review'
      'yellow-400'
    when 'event'
      'purple-400'
    else
      'gray-400'
    end
  end

  private

  def pending_movies_count
    @pending_movies_count ||= Movie.where(validation_status: :pending).count
  end

  def pending_participations_count
    @pending_participations_count ||= Participation.where(status: :pending).count
  end

  def system_errors_count
    # This would integrate with error tracking service
    0 # Placeholder
  end
end
