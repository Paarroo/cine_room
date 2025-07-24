class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_EMAIL", "codes.sources.0@gmail.com")
  layout "mailer"
end
