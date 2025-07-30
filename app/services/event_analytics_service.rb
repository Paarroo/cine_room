class EventAnalyticsService
  def initialize(event)
    @event = event
  end

  # Calculate event revenue from confirmed participations
  def calculate_revenue
    @event.participations.where(status: [:confirmed, :attended])
          .sum("#{@event.price_cents} * participations.seats") / 100.0
  end

  # Calculate comprehensive booking analytics for event
  def calculate_booking_analytics
    participations = confirmed_participations

    {
      total_bookings: participations.count,
      total_seats_sold: participations.sum(:seats),
      average_booking_size: participations.average(:seats)&.round(1) || 0,
      booking_conversion_rate: calculate_booking_conversion_rate,
      daily_bookings: calculate_daily_bookings
    }
  end

  # Calculate capacity metrics
  def calculate_capacity_metrics
    confirmed_seats = confirmed_participations.sum(:seats)

    {
      total_capacity: @event.max_capacity,
      seats_sold: confirmed_seats,
      seats_available: @event.max_capacity - confirmed_seats,
      occupancy_rate: occupancy_rate(confirmed_seats),
      is_sold_out: confirmed_seats >= @event.max_capacity
    }
  end

  # Get recent activities for event
  def get_recent_activities(limit: 5)
    activities = []

    # Recent participations
    @event.participations.includes(:user)
          .order(created_at: :desc)
          .limit(limit)
          .each do |participation|
      activities << {
        type: 'participation',
        title: 'Nouvelle participation',
        description: "#{participation.user&.full_name} - #{participation.seats} place(s)",
        status: participation.status,
        created_at: participation.created_at
      }
    end

    activities.sort_by { |a| a[:created_at] }.reverse
  end

  # Calculate all metrics at once for dashboard display
  def calculate_all_metrics
    {
      revenue: calculate_revenue,
      booking_analytics: calculate_booking_analytics,
      capacity_metrics: calculate_capacity_metrics,
      recent_activities: get_recent_activities
    }
  end

  private

  def confirmed_participations
    @confirmed_participations ||= @event.participations.where(status: [:confirmed, :attended])
  end

  def calculate_booking_conversion_rate
    total_users = User.count
    total_bookings = confirmed_participations.count

    return 0 if total_users.zero?

    (total_bookings.to_f / total_users * 100).round(2)
  end

  def calculate_daily_bookings
    confirmed_participations
      .group("DATE(created_at)")
      .count
      .transform_keys { |date| date.strftime('%d/%m') }
  end

  def occupancy_rate(confirmed_seats)
    return 0 if @event.max_capacity.zero?
    
    (confirmed_seats.to_f / @event.max_capacity * 100).round(1)
  end
end