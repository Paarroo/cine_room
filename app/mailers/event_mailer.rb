class EventMailer < ApplicationMailer
  default from: 'noreply@cineroom.com'

  def event_approved(event)
    @event = event
    @creator = event.created_by
    
    mail(
      to: @creator.email,
      subject: "✅ Votre événement '#{@event.title}' a été approuvé"
    )
  end

  def event_rejected(event, reason = 'Aucune raison spécifiée')
    @event = event
    @creator = event.created_by
    @reason = reason
    
    mail(
      to: @creator.email,
      subject: "❌ Votre événement '#{@event.title}' a été rejeté"
    )
  end
end
