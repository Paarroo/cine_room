# Preview all emails at http://localhost:3000/rails/mailers/event_mailer_mailer
class EventMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/event_mailer_mailer/event_approved
  def event_approved
    EventMailer.event_approved
  end

  # Preview this email at http://localhost:3000/rails/mailers/event_mailer_mailer/event_rejected
  def event_rejected
    EventMailer.event_rejected
  end

end
