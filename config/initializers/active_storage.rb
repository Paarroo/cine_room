# Disable ActiveStorage analysis in production to prevent SolidQueue issues
if Rails.env.production?
  Rails.application.config.active_storage.queues.analysis = false
  Rails.application.config.active_storage.queues.purge = false
end