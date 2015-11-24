source 'https://rubygems.org'
ruby '2.2.3'

# Core
gem 'rails', '~> 4.2.4'
gem 'jbuilder', '~> 2.0'
gem 'haml-rails'
gem 'paper_trail', '~> 4.0.0.beta'
gem 'virtus'
gem 'ancestry'

# Assets
gem 'jquery-rails'
gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '>= 1.3.0'

gem 'clockwork', require: false
gem 'faker'
gem 'netaddr'
gem 'unf'
gem 'useragent', '~> 0.10.0'
gem 'omniauth-gplus',
  git: 'https://github.com/ministryofjustice/omniauth-gplus.git'

# Image uploads
gem 'fog'
gem 'mini_magick'
gem 'carrierwave'
gem 'carrierwave-bombshelter'

# Email & metrics
gem 'mail'
gem 'premailer-rails'
gem 'recipient_interceptor', '~> 0.1.2'
gem 'keen'

# Helpers
gem 'will_paginate', '~> 3.0'
gem 'friendly_id', '~> 5.0.0'

# Gov UK Helpers
gem 'govspeak'
gem 'govuk_frontend_toolkit'
gem 'govuk_template'
gem 'moj_internal_template', '~> 0.1.7'

# Search
gem 'elasticsearch-model'
gem 'elasticsearch-rails'

# Workers
gem 'delayed_job_active_record'

# Database
gem 'pg'

# Server
gem 'unicorn', '~> 4.8.3'

group :production do
  gem 'sentry-raven', :git => 'https://github.com/getsentry/raven-ruby.git'
  gem 'logstasher', '~> 0.6.2'
end

group :staging do
  gem 'rails_12factor'
end

group :development do
  gem 'foreman'
  gem 'mailcatcher'
  gem 'brakeman', require: false
  gem 'spring-commands-rspec'
  gem 'web-console'
end

group :development, :development, :test do
  gem 'factory_girl_rails' # used on MailPreview, hence needed on staging
end

group :development, :test do
  gem 'jshint'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'rspec-rails'
end

group :development, :test, :assets do
  gem 'dotenv-rails'
end

group :test do
  gem 'codeclimate-test-reporter', require: nil
  gem 'fuubar'
  gem 'database_cleaner'
  gem 'site_prism'
  gem 'capybara'
  gem 'launchy'
  gem 'minitest'
  gem 'poltergeist'
  gem 'timecop'
  gem 'simplecov', require: false
  gem 'simplecov-rcov', require: false
  gem 'shoulda-matchers', require: false
end
