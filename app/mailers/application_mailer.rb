class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('GMAIL_USERNAME', 'codes.sources.0@gmail.com')
  layout "mailer"
end
