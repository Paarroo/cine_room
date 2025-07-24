module ParticipationsManagement
  extend ActiveSupport::Concern

  # Get all scopes for participation filtering - mirrors ActiveAdmin scopes
  def participation_scopes
    {
      all: Participation.all,
      pending: Participation.where(status: :pending),
      confirmed: Participation.where(status: :confirmed),
      cancelled: Participation.where(status: :cancelled)
    }
  end

  # Build participation query with includes for performance - mirrors ActiveAdmin index
  def build_participation_query
    Participation.includes(:user, :event, event: :movie)
                 .order(created_at: :desc)
  end

  # Calculate total price for a participation - mirrors ActiveAdmin total_price column
  def calculate_participation_total_price(participation)
    return 0 unless participation.event&.price_cents && participation.seats

    (participation.event.price_cents * participation.seats) / 100.0
  end

  # MAIN STATS METHOD - Fixed name to match controller usage
  def calculate_participation_statistics
    {
      total: Participation.count,
      pending: Participation.where(status: :pending).count,
      confirmed: Participation.where(status: :confirmed).count,
      cancelled: Participation.where(status: :cancelled).count,
      attended: Participation.where(status: :attended).count,
      today: Participation.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count,
      this_week: Participation.where(created_at: 1.week.ago..Time.current).count,
      this_month: Participation.where(created_at: 1.month.ago..Time.current).count,
      total_revenue: calculate_total_participation_revenue,
      average_participation_value: calculate_average_participation_value
    }
  end

  # Format participation display data - mirrors ActiveAdmin columns
  def format_participation_data(participation)
    {
      id: participation.id,
      user_name: participation.user&.full_name || 'Unknown User',
      user_link: participation.user,
      event_title: participation.event&.title || 'Unknown Event',
      event_link: participation.event,
      movie_title: participation.event&.movie&.title,
      movie_link: participation.event&.movie,
      event_date: participation.event&.event_date,
      seats: participation.seats,
      total_price: calculate_participation_total_price(participation),
      formatted_total_price: format_currency(calculate_participation_total_price(participation)),
      status: participation.status,
      status_humanized: participation.status.humanize,
      has_payment: participation.stripe_payment_id.present?,
      payment_indicator: participation.stripe_payment_id.present? ? "✓" : "✗",
      stripe_payment_id: participation.stripe_payment_id,
      formatted_created_at: participation.created_at.strftime("%d/%m/%Y"),
      created_at: participation.created_at,
      updated_at: participation.updated_at
    }
  end

  # Get collections for form dropdowns - mirrors ActiveAdmin form collections
  def get_participation_form_collections
    {
      users: User.all.map { |u| [ u.full_name, u.id ] },
      events: Event.all.map { |e| [ "#{e.title} - #{e.event_date}", e.id ] },
      statuses: Participation.statuses.map { |key, value| [ key.humanize, key ] }
    }
  end

  # Bulk confirm participations - mirrors ActiveAdmin batch_action
  def bulk_confirm_participations(participation_ids)
    return { success: false, count: 0, error: 'No participations provided' } if participation_ids.blank?

    begin
      updated_count = Participation.where(id: participation_ids).update_all(status: :confirmed)

      # Update related event statuses after bulk operation
      update_events_status_after_bulk_operation(participation_ids)

      {
        success: true,
        count: updated_count,
        message: "#{updated_count} participations confirmed successfully!"
      }
    rescue StandardError => e
      Rails.logger.error "Bulk confirm participations error: #{e.message}"
      {
        success: false,
        count: 0,
        error: e.message
      }
    end
  end

  # Bulk cancel participations - mirrors ActiveAdmin batch_action
  def bulk_cancel_participations(participation_ids)
    return { success: false, count: 0, error: 'No participations provided' } if participation_ids.blank?

    begin
      updated_count = Participation.where(id: participation_ids).update_all(status: :cancelled)

      # Update related event statuses after bulk operation
      update_events_status_after_bulk_operation(participation_ids)

      {
        success: true,
        count: updated_count,
        message: "#{updated_count} participations cancelled successfully!"
      }
    rescue StandardError => e
      Rails.logger.error "Bulk cancel participations error: #{e.message}"
      {
        success: false,
        count: 0,
        error: e.message
      }
    end
  end

  # Individual participation status update
  def update_participation_status(participation, new_status)
    return { success: false, error: 'Invalid participation' } unless participation
    return { success: false, error: 'Invalid status' } unless Participation.statuses.key?(new_status)

    begin
      participation.update!(status: new_status)

      # Update event status if needed
      update_event_status_if_needed(participation.event)

      {
        success: true,
        participation: participation,
        message: "Participation #{new_status} successfully"
      }
    rescue StandardError => e
      Rails.logger.error "Update participation status error: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Filter participations based on parameters
  def filter_participations(params)
    participations = build_participation_query

    # Apply scope filter
    if params[:scope].present? && participation_scopes.key?(params[:scope].to_sym)
      participations = participation_scopes[params[:scope].to_sym]
                      .includes(:user, :event, event: :movie)
                      .order(created_at: :desc)
    end

    # Status filter
    participations = participations.where(status: params[:status]) if params[:status].present?

    # Event filter
    participations = participations.where(event_id: params[:event_id]) if params[:event_id].present?

    # User search
    if params[:user_search].present?
      search_term = "%#{params[:user_search]}%"
      participations = participations.joins(:user)
                                   .where("users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ?",
                                          search_term, search_term, search_term)
    end

    # Date range filters
    case params[:date_filter]
    when "today"
      participations = participations.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
    when "week"
      participations = participations.where(created_at: 1.week.ago..Time.current)
    when "month"
      participations = participations.where(created_at: 1.month.ago..Time.current)
    end

    # Payment filter
    case params[:payment_filter]
    when "with_payment"
      participations = participations.where.not(stripe_payment_id: [ nil, '' ])
    when "without_payment"
      participations = participations.where(stripe_payment_id: [ nil, '' ])
    end

    participations
  end

  # Get revenue data for participations
  def calculate_participation_revenue
    confirmed_participations = Participation.where(status: [ :confirmed, :attended ]).joins(:event)

    {
      total_revenue: confirmed_participations.sum("events.price_cents * participations.seats") / 100.0,
      monthly_revenue: confirmed_participations
                      .where(created_at: Date.current.beginning_of_month..Date.current.end_of_month)
                      .sum("events.price_cents * participations.seats") / 100.0,
      weekly_revenue: confirmed_participations
                     .where(created_at: 1.week.ago..Time.current)
                     .sum("events.price_cents * participations.seats") / 100.0,
      average_participation_value: calculate_average_participation_value
    }
  end

  # Export participation data for CSV/reports
  def export_participation_data(participations)
    participations.map do |participation|
      {
        id: participation.id,
        user_name: participation.user&.full_name,
        user_email: participation.user&.email,
        event_title: participation.event&.title,
        movie_title: participation.event&.movie&.title,
        event_date: participation.event&.event_date,
        venue: participation.event&.venue_name,
        seats: participation.seats,
        total_price: calculate_participation_total_price(participation),
        status: participation.status.humanize,
        payment_id: participation.stripe_payment_id,
        created_at: participation.created_at.strftime("%d/%m/%Y %H:%M"),
        updated_at: participation.updated_at.strftime("%d/%m/%Y %H:%M")
      }
    end
  end

  private

  # Calculate total revenue from all confirmed participations
  def calculate_total_participation_revenue
    Participation.where(status: [ :confirmed, :attended ])
                 .joins(:event)
                 .sum("events.price_cents * participations.seats") / 100.0
  end

  # Update event status based on current participations
  def update_event_status_if_needed(event)
    return unless event

    confirmed_seats = event.participations.where(status: [ :confirmed, :attended ]).sum(:seats)

    if confirmed_seats >= event.max_capacity && !event.sold_out?
      event.update!(status: :sold_out)
    elsif confirmed_seats < event.max_capacity && event.sold_out?
      event.update!(status: :upcoming)
    end
  rescue StandardError => e
    Rails.logger.error "Update event status error: #{e.message}"
  end

  # Update multiple events status after bulk operations
  def update_events_status_after_bulk_operation(participation_ids)
    events_to_update = Event.joins(:participations)
                           .where(participations: { id: participation_ids })
                           .distinct

    events_to_update.each { |event| update_event_status_if_needed(event) }
  end

  # Calculate average value per participation
  def calculate_average_participation_value
    confirmed_participations = Participation.where(status: [ :confirmed, :attended ]).joins(:event)
    total_count = confirmed_participations.count

    return 0 if total_count.zero?

    total_revenue = confirmed_participations.sum("events.price_cents * participations.seats") / 100.0
    (total_revenue / total_count).round(2)
  end

  # Format currency for display
  def format_currency(amount)
    return "€0.00" if amount.nil? || amount.zero?

    "€#{sprintf('%.2f', amount)}"
  end

  # Validate participation data before operations
  def validate_participation_data(participation_params)
    errors = []

    errors << "User is required" if participation_params[:user_id].blank?
    errors << "Event is required" if participation_params[:event_id].blank?
    errors << "Seats must be positive" if participation_params[:seats].to_i <= 0

    # Check event capacity if creating new participation
    if participation_params[:event_id].present?
      event = Event.find_by(id: participation_params[:event_id])
      if event
        current_confirmed_seats = event.participations.where(status: [ :confirmed, :attended ]).sum(:seats)
        requested_seats = participation_params[:seats].to_i

        if (current_confirmed_seats + requested_seats) > event.max_capacity
          errors << "Not enough seats available (#{event.available_spots} remaining)"
        end
      end
    end

    {
      valid: errors.empty?,
      errors: errors
    }
  end
end
