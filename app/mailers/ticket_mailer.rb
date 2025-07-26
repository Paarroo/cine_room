class TicketMailer < ApplicationMailer
  default from: ENV.fetch('GMAIL_USERNAME', 'codes.sources.0@gmail.com')

  def ticket_confirmation(participation)
    @participation = participation
    @user = participation.user
    @event = participation.event
    @movie = participation.event.movie

    # Generate QR code as PNG attachment
    qr_code_png = @participation.qr_code_png
    attachments["ticket_qr_code_#{@participation.id}.png"] = qr_code_png

    mail(
      to: @user.email,
      subject: "🎫 Votre billet pour #{@event.title} - CinéRoom"
    )
  end
end