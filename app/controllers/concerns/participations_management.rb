module ParticipationManagement
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
