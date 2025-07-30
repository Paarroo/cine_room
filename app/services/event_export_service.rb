require 'csv'

class EventExportService
  def initialize(event)
    @event = event
  end

  # Export event participations data with comprehensive information
  def export_participations_data
    @event.participations.includes(:user).map do |participation|
      {
        id: participation.id,
        user_name: participation.user&.full_name,
        user_email: participation.user&.email,
        seats: participation.seats,
        total_price: (@event.price_cents * participation.seats) / 100.0,
        status: participation.status.humanize,
        payment_id: participation.stripe_payment_id,
        booking_date: participation.created_at.strftime('%d/%m/%Y %H:%M'),
        user_phone: participation.user&.phone,
        special_requirements: participation.special_requirements
      }
    end
  end

  # Generate CSV for participations export with proper headers
  def generate_participations_csv
    data = export_participations_data
    return '' if data.empty?

    headers = data.first.keys
    CSV.generate(headers: true) do |csv|
      csv << headers.map(&:to_s).map(&:humanize)
      data.each { |row| csv << headers.map { |h| row[h] } }
    end
  end

  # Generate filename for export with timestamp
  def generate_export_filename(format = 'csv')
    "event_#{@event.id}_participations_#{Date.current.strftime('%Y%m%d')}.#{format}"
  end

  # Export event summary data
  def export_event_summary
    analytics = EventAnalyticsService.new(@event)
    metrics = analytics.calculate_all_metrics

    {
      event_id: @event.id,
      event_title: @event.title,
      event_date: @event.event_date.strftime('%d/%m/%Y'),
      venue_name: @event.venue_name,
      venue_address: @event.venue_address,
      max_capacity: @event.max_capacity,
      price: @event.price_cents / 100.0,
      status: @event.status.humanize,
      total_revenue: metrics[:revenue],
      seats_sold: metrics[:capacity_metrics][:seats_sold],
      occupancy_rate: "#{metrics[:capacity_metrics][:occupancy_rate]}%",
      total_bookings: metrics[:booking_analytics][:total_bookings],
      export_generated_at: Time.current.strftime('%d/%m/%Y %H:%M')
    }
  end

  # Generate comprehensive CSV with both event data and participations
  def generate_comprehensive_csv
    event_summary = export_event_summary
    participations_data = export_participations_data

    CSV.generate(headers: true) do |csv|
      # Event summary section
      csv << ['RÉSUMÉ DE L\'ÉVÉNEMENT', '']
      event_summary.each do |key, value|
        csv << [key.to_s.humanize, value]
      end

      # Empty row for separation
      csv << ['', '']

      # Participations section
      if participations_data.any?
        csv << ['PARTICIPATIONS', '']
        headers = participations_data.first.keys
        csv << headers.map(&:to_s).map(&:humanize)
        
        participations_data.each do |row|
          csv << headers.map { |h| row[h] }
        end
      else
        csv << ['Aucune participation pour cet événement', '']
      end
    end
  end

  # Export statistics for multiple events (class method)
  def self.export_events_statistics(events)
    CSV.generate(headers: true) do |csv|
      csv << [
        'ID Événement', 'Titre', 'Date', 'Lieu', 'Capacité Max', 
        'Places Vendues', 'Revenus (€)', 'Taux d\'Occupation (%)', 'Statut'
      ]

      events.each do |event|
        analytics = EventAnalyticsService.new(event)
        metrics = analytics.calculate_all_metrics

        csv << [
          event.id,
          event.title,
          event.event_date.strftime('%d/%m/%Y'),
          event.venue_name,
          event.max_capacity,
          metrics[:capacity_metrics][:seats_sold],
          metrics[:revenue],
          metrics[:capacity_metrics][:occupancy_rate],
          event.status.humanize
        ]
      end
    end
  end

  # Generate export response data for JSON API
  def export_response_data(format: :csv)
    filename = generate_export_filename(format.to_s)
    
    {
      success: true,
      data: format == :json ? export_participations_data : nil,
      filename: filename,
      download_url: Rails.application.routes.url_helpers.admin_event_export_participations_path(
        @event, format: format
      )
    }
  end
end