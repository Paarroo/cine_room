source "https://rubygems.org"
ruby "3.4.2"

gem "rails", "~> 8.0.2"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

gem "devise"
gem "cancancan"

gem 'activeadmin', '~> 3.2'

gem "stripe"
gem "stripe_event"
gem "money-rails"
gem "kaminari"
gem "chronic"
gem "friendly_id"

gem "noticed"

gem "turbo_power"
gem "view_component"

gem "image_processing", "~> 1.2"
gem "aws-sdk-s3", require: false

gem "premailer-rails"
gem "nokogiri"

gem "geocoder"
gem "leaflet-rails"

gem "sidekiq"

gem "rails-erd"
gem "bullet"
gem "annotate"

gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

gem "tzinfo-data", platforms: %i[windows jruby]
group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "dotenv-rails"


  group :development, :test do
    gem "rspec-rails"
    gem 'factory_bot_rails', '~> 6.4'
    gem 'faker', '~> 3.2'
  end

  group :test do
    gem 'shoulda-matchers', '~> 6.0'
    gem 'nyan-cat-formatter', '~> 0.12'
  end

  gem "pry-rails"
  gem "pry-byebug"
  gem "table_print"
end
group :development do
  gem "web-console"

  gem "letter_opener"
  gem "letter_opener_web"
  gem "localhost"

  gem "rubocop-rails"
  gem "rubocop-performance"

  gem "better_errors"
  gem "binding_of_caller"

  gem "listen"
  gem "spring"
  gem "spring-watcher-listen"
  gem "rerun"
  gem "guard"
  gem "guard-rails"
  gem "guard-livereload"
  gem "rack-livereload"

  gem "colorize"
  gem "tty-spinner"
  gem "tty-progressbar"

  gem "awesome_print"
  gem "hirb"

  gem "rails_panel"
  gem "meta_request"

  gem "rails_semantic_logger"
  gem "lograge"

  gem "seed_dump"

  gem 'rails-i18n'
  gem 'devise-i18n'
  gem 'http_accept_language'

end
group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "simplecov", require: false
  gem "database_cleaner-active_record"
  gem "webmock"
  gem "vcr"
end
group :production do
  gem "rails_12factor"
  gem "rack-timeout"
  gem "newrelic_rpm"
  gem "sentry-ruby"
end
