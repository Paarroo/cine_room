# config/puma.rb - Version Rails 8.0.2 compatible

# The environment Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT") { 3000 }

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments.
if ENV["SOLID_QUEUE_IN_PUMA"]
  plugin :solid_queue
end

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set this if you need it.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Workers do not work on all platforms. Please see Puma's documentation
# for more information.
# https://github.com/puma/puma/blob/master/docs/deployment.md#clustering
#
# workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
# preload_app!
