module Admin::DashboardHelper
  # Generate revenue chart data for the last 30 days
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

  # Generate user growth chart data
  def user_growth_chart_data
    @user_growth_chart_data ||= begin
      (12.months.ago.beginning_of_month..Date.current.end_of_month).group_by(&:month).map do |month, dates|
        month_start = dates.first.beginning_of_month
        month_end = dates.first.end_of_month

        new_users = User.where(created_at: month_start..month_end).count

        {
          month: month_start.strftime("%b %Y"),
          users: new_users,
          cumulative: User.where(created_at: ..month_end).count
        }
      end
    end
  end

  # Generate participation trends data
  def participation_trends_data
    @participation_trends_data ||= begin
      (7.days.ago.to_date..Date.current).map do |date|
        daily_participations = Participation.where(created_at: date.beginning_of_day..date.end_of_day)

        {
          date: date.strftime("%a %d"),
          confirmed: daily_participations.where(status: :confirmed).count,
          pending: daily_participations.where(status: :pending).count,
          cancelled: daily_participations.where(status: :cancelled).count
        }
      end
    end
  end

  # Get status-specific colors for charts
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
