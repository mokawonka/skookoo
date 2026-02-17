source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.2'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Puma as the app server
gem 'puma', '~> 6.1.1'
#To fix testMailer error
gem 'net-smtp' # to send email
gem 'net-imap' # for rspec
gem 'net-pop'  # for rspec
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'

#alternative to webpacker (rails 7)
gem 'importmap-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'

#epub to txt conversion
gem 'epub-parser', '~> 0.5.0'
gem 'henkei', '~> 2.3'

# unzipping epub file
gem 'rubyzip', '~> 2.3.2' , require: 'zip'

gem 'stimulus-rails'
gem "sprockets-rails"


# Use Active Storage variant
gem 'image_processing', '~> 1.2'

gem 'pagy', '~> 5.10' # omit patch digit
gem 'pg_search', '~> 2.3.6'

gem 'email_validator' 
gem 'sha3', '~> 1.0', '>= 1.0.1'
gem "noticed", "~> 2.9"
gem 'turbo-rails'
gem "redis", "~> 5.0"

gem 'grover'
gem 'meta-tags'

gem 'stripe'

gem "aws-sdk-s3", require: false

gem 'google-cloud-ai_platform' 

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
