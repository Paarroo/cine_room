class ParticipationMailer < ApplicationMailer

  def confirmation_email(participation)
    @participation = participation
    @user = participation.user
    @event = participation.event

    mail(to: @user.email, subject: "Confirmation de votre participation à l'évènement << #{@event.title} >>")
  end
end
