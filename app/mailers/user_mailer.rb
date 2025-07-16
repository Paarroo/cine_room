class UserMailer < ApplicationMailer
  default from: 'no-reply@cineroom.com'

  def welcome_email(user)
    @user = user
    @url = root_url
    mail(to: @user.email, subject: 'Bienvenue sur CinéRoom !')
  end
end
