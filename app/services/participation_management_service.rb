class ParticipationManagementService
  def initialize(participations_scope = nil)
    @participations_scope = participations_scope || Participation.all
  end

  def calculate_statistics
    {
      total: @participations_scope.count,
      pending: @participations_scope.where(status: :pending).count,
      confirmed: @participations_scope.where(status: :confirmed).count,
      attended: @participations_scope.where(status: :attended).count,
      cancelled: @participations_scope.where(status: :cancelled).count,
      total_revenue: calculate_total_revenue,
      average_seats: @participations_scope.average(:seats)&.round(2) || 0
    }
  end

  def calculate_insights
    {
      conversion_rate: calculate_conversion_rate,
      average_booking_time: calculate_average_booking_time,
      peak_booking_hours: calculate_peak_booking_hours,
      attendance_rate: calculate_attendance_rate
    }
  end

  def calculate_revenue_data
    {
      total_revenue: calculate_total_revenue,
      monthly_revenue: calculate_monthly_revenue,
      daily_revenue: calculate_daily_revenue
    }
  end

  def format_participation_data(participation)
    {
      id: participation.id,
      user_name: participation.user&.full_name || 'N/A',
      user_email: participation.user&.email || 'N/A',
      event_title: participation.event&.title || 'N/A',
      movie_title: participation.event&.movie&.title || 'N/A',
      event_date: participation.event&.event_date || 'N/A',
      event_date_formatted: participation.event&.event_date&.strftime('%d/%m/%Y') || 'N/A',
      seats: participation.seats,
      status: participation.status.humanize,
      created_at: participation.created_at,
      created_at_formatted: participation.created_at.strftime('%d/%m/%Y %H:%M'),
      updated_at: participation.updated_at,
      updated_at_formatted: participation.updated_at.strftime('%d/%m/%Y %H:%M'),
      revenue: calculate_single_participation_revenue(participation)
    }
  end

  def bulk_confirm_participations(participation_ids)
    participations = Participation.where(id: participation_ids, status: :pending)
    
    if participations.empty?
      return { success: false, error: 'Aucune participation éligible trouvée' }
    end

    confirmed_count = 0
    participations.find_each do |participation|
      if participation.update(status: :confirmed)
        confirmed_count += 1
      end
    end

    {
      success: true,
      message: "#{confirmed_count} participations confirmées",
      count: confirmed_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def bulk_cancel_participations(participation_ids)
    participations = Participation.where(id: participation_ids).where.not(status: :cancelled)
    
    if participations.empty?
      return { success: false, error: 'Aucune participation éligible trouvée' }
    end

    cancelled_count = 0
    participations.find_each do |participation|
      if participation.update(status: :cancelled)
        cancelled_count += 1
      end
    end

    {
      success: true,
      message: "#{cancelled_count} participations annulées",
      count: cancelled_count
    }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def export_data(participations_scope)
    participations_scope.includes(:user, :event, event: :movie).map do |participation|
      format_participation_data(participation).merge({
        stripe_payment_id: participation.stripe_payment_id,
        venue: participation.event&.venue_name || 'N/A',
        price: participation.event&.price_cents ? (participation.event.price_cents / 100.0) : 0
      })
    end
  end

  def get_filter_options
    {
      statuses: Participation.statuses.keys.map { |s| [s.humanize, s] },
      events: Event.joins(:participations).distinct.limit(20).pluck(:title, :id),
      venues: Event.joins(:participations).distinct.pluck(:venue_name).compact.uniq
    }
  end

  def top_events_by_participation(limit = 5)
    Event.joins(:participations)
         .where(participations: { status: [:confirmed, :attended] })
         .group('events.id')
         .order('COUNT(participations.id) DESC')
         .limit(limit)
         .includes(:movie)
  end

  def most_active_participants(limit = 5)
    User.joins(:participations)
        .where(participations: { status: [:confirmed, :attended] })
        .group('users.id')
        .order('COUNT(participations.id) DESC')
        .limit(limit)
  end

  private

  def calculate_total_revenue
    @participations_scope.joins(:event)
                        .where(status: [:confirmed, :attended])
                        .sum('events.price_cents * participations.seats') / 100.0
  end

  def calculate_monthly_revenue
    @participations_scope.joins(:event)
                        .where(status: [:confirmed, :attended])
                        .where(created_at: 1.month.ago..Time.current)
                        .sum('events.price_cents * participations.seats') / 100.0
  end

  def calculate_daily_revenue
    @participations_scope.joins(:event)
                        .where(status: [:confirmed, :attended])
                        .where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
                        .sum('events.price_cents * participations.seats') / 100.0
  end

  def calculate_single_participation_revenue(participation)
    return 0 unless participation.event&.price_cents && participation.seats
    (participation.event.price_cents * participation.seats) / 100.0
  end

  def calculate_attendance_rate
    total_confirmed = @participations_scope.where(status: [:confirmed, :attended]).count
    total_attended = @participations_scope.where(status: :attended).count

    return 0 if total_confirmed.zero?

    (total_attended.to_f / total_confirmed * 100).round(1)
  end

  def calculate_conversion_rate
    total_users = User.count
    participants = User.joins(:participations).distinct.count

    return 0 if total_users.zero?

    (participants.to_f / total_users * 100).round(1)
  end

  def calculate_average_booking_time
    bookings_with_user_age = @participations_scope.joins(:user)
                                                 .where(status: [:confirmed, :attended])
                                                 .where.not(users: { created_at: nil })

    return 0 if bookings_with_user_age.empty?

    total_days = bookings_with_user_age.sum do |p|
      (p.created_at.to_date - p.user.created_at.to_date).to_i
    end

    (total_days.to_f / bookings_with_user_age.count).round(1)
  end

  def calculate_peak_booking_hours
    @participations_scope.where(status: [:confirmed, :attended])
                        .group("EXTRACT(hour FROM created_at)")
                        .count
                        .sort_by { |hour, count| -count }
                        .first(3)
                        .map { |hour, count| { hour: hour.to_i, count: count } }
  end
end