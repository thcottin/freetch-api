source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.0'

group :development, :test do
  gem 'rspec-rails', '~> 3.0.0.beta'
  gem 'sqlite3', '1.3.8'
  gem 'rails_layout'
end

group :test do
  gem 'selenium-webdriver', '2.35.1'
  gem 'capybara', '2.2.1' # Version 2.2.0 does not work with rspec 3.0.0
  gem 'factory_girl_rails', '4.2.1'
end

group :production, :staging do
  # Sets up the Rails 4 logger to STDOUT
  gem 'rails_12factor', '0.0.2'
end

gem 'pubnub'
gem 'pg', '0.15.1'
gem 'mixpanel-ruby'
gem 'bootstrap-sass'
gem 'database_cleaner'

gem 'twilio-ruby', '~> 3.11'

# Monitor app
gem 'newrelic_rpm'

# To store spots in memory with fast access
gem "redis", "~> 3.0.1"

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

gem 'urbanairship'

gem 'state_machine'
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

# Use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
gem 'unicorn'

# Stripe for payment
gem 'stripe'

# User agent
gem 'useragent'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]
