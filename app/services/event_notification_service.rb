class EventNotificationService
  def initialize(event)
    @event = event
  end

  def send_event_notification
    participants = @event.participations.where(status: [:confirmed, :attended])
                          .includes(:user)

    sent_count = 0
    errors = []

    participants.find_each do |participation|
      begin
        EventMailer.event_notification(participation).deliver_now
        sent_count += 1
      rescue StandardError => e
        errors << "Failed to send to #{participation.user&.email}: #{e.message}"
      end
    end

    if errors.empty?
      {
        success: true,
        message: "Notifications envoyées avec succès à #{sent_count} participants",
        sent_count: sent_count
      }
    else
      {
        success: false,
        error: "Erreurs lors de l'envoi: #{errors.join(', ')}",
        sent_count: sent_count
      }
    end
  end

  def send_bulk_notifications(events)
    total_sent = 0
    total_errors = []

    events.each do |event|
      service = EventNotificationService.new(event)
      result = service.send_event_notification
      
      if result[:success]
        total_sent += result[:sent_count]
      else
        total_errors << "Event #{event.title}: #{result[:error]}"
      end
    end

    {
      success: total_errors.empty?,
      message: total_errors.empty? ? 
        "Notifications envoyées à #{total_sent} participants" :
        "Erreurs: #{total_errors.join('; ')}",
      sent_count: total_sent,
      errors: total_errors
    }
  end

  def send_reminder_notifications(days_before = 1)
    upcoming_events = Event.where(
      event_date: days_before.days.from_now.beginning_of_day..days_before.days.from_now.end_of_day,
      status: :upcoming
    )

    results = []
    upcoming_events.each do |event|
      service = EventNotificationService.new(event)
      result = service.send_event_notification
      results << { event: event.title, result: result }
    end

    total_sent = results.sum { |r| r[:result][:sent_count] || 0 }
    failed_events = results.select { |r| !r[:result][:success] }

    {
      success: failed_events.empty?,
      message: failed_events.empty? ? 
        "Rappels envoyés pour #{upcoming_events.count} événements (#{total_sent} participants)" :
        "Erreurs pour certains événements",
      events_processed: upcoming_events.count,
      total_sent: total_sent,
      failed_events: failed_events
    }
  end
end