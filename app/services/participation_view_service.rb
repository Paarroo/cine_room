class ParticipationViewService
  def initialize(participation = nil)
    @participation = participation
  end

  def prepare_show_data(participation)
    {
      participation_data: ParticipationManagementService.new.format_participation_data(participation),
      user: participation.user,
      event: participation.event,
      movie: participation.event&.movie,
      can_modify: can_modify_participation?(participation),
      participation_revenue: calculate_single_participation_revenue(participation),
      related_participations: find_related_participations(participation),
      booking_lead_time: calculate_booking_lead_time(participation)
    }
  end

  def prepare_index_data(participations, params)
    service = ParticipationManagementService.new(Participation.all)
    
    {
      formatted_participations: participations.map { |p| service.format_participation_data(p) },
      stats: service.calculate_statistics,
      insights: service.calculate_insights,
      filter_options: service.get_filter_options,
      revenue_data: service.calculate_revenue_data,
      top_events: service.top_events_by_participation(5),
      active_participants: service.most_active_participants(5),
      attendance_rates: service.calculate_insights[:attendance_rate]
    }
  end

  def prepare_stats_data
    service = ParticipationManagementService.new
    {
      stats: service.calculate_statistics,
      insights: service.calculate_insights,
      pending_confirmations: Participation.where(status: :pending).count,
      todays_events: Event.where(event_date: Date.current).joins(:participations).distinct.count,
      revenue_today: service.calculate_revenue_data[:daily_revenue]
    }
  end

  def prepare_export_data(participations_scope)
    service = ParticipationManagementService.new
    service.export_data(participations_scope)
  end

  private

  def can_modify_participation?(participation)
    participation.event&.event_date && participation.event.event_date >= Date.current
  end

  def calculate_single_participation_revenue(participation)
    return 0 unless participation.event&.price_cents && participation.seats
    (participation.event.price_cents * participation.seats) / 100.0
  end

  def find_related_participations(participation)
    Participation.joins(:event)
                 .where(events: { id: participation.event_id })
                 .where.not(id: participation.id)
                 .includes(:user)
                 .order(created_at: :desc)
                 .limit(10)
  end

  def calculate_booking_lead_time(participation)
    return nil unless participation.event.event_date
    (participation.event.event_date - participation.created_at.to_date).to_i
  end
end