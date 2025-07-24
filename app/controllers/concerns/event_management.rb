module EventManagement
  extend ActiveSupport::Concern

  def complete_event_action(event)
    event.update!(
      status: :completed,
      updated_at: Time.current
    )
  end

  def cancel_event_action(event)
    event.update!(
      status: :cancelled,
      updated_at: Time.current
    )
  end

  def reopen_event_action(event)
    event.update!(
      status: :upcoming,
      updated_at: Time.current
    )
  end

  def bulk_complete_events(event_ids)
    Event.where(id: event_ids).update_all(
      status: :completed,
      updated_at: Time.current
    )
  end

  def bulk_cancel_events(event_ids)
    Event.where(id: event_ids).update_all(
      status: :cancelled,
      updated_at: Time.current
    )
  end

  def calculate_event_stats
    {
      total: Event.count,
      upcoming: Event.where(status: :upcoming).count,
      completed: Event.where(status: :completed).count,
      sold_out: Event.where(status: :sold_out).count,
      cancelled: Event.where(status: :cancelled).count
    }
  end

  def filter_events(params)
    events = Event.includes(:movie, :participations, :users)

    # Filter by status
    events = events.where(status: params[:status]) if params[:status].present?

    # Filter by venue
    events = events.where(venue_name: params[:venue]) if params[:venue].present?

    # Filter by movie genre
    events = events.joins(:movie).where(movies: { genre: params[:genre] }) if params[:genre].present?

    # Date filters
    case params[:date_filter]
    when "week"
      events = events.where(event_date: Date.today..Date.today.end_of_week)
    when "month"
      events = events.where(event_date: Date.today..Date.today.end_of_month)
    when "past"
      events = events.where(event_date: ...Date.today)
    end

    # Search
    if params[:q].present?
      events = events.where("title ILIKE ? OR venue_name ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    events.order(event_date: :desc)
  end

  def calculate_event_revenue(event)
    event.participations.where(status: :confirmed).sum("price_cents * seats") / 100.0
  end

  def get_filter_options
    {
      venues: Event.distinct.pluck(:venue_name).compact.sort,
      genres: Movie.joins(:events).distinct.pluck(:genre).compact.sort,
      statuses: Event.statuses.keys
    }
  end
end
