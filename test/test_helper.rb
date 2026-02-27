ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all  # Disabled to avoid foreign key constraint issues

  # Add more helper methods to be used by all tests here...
  
  # Helper method for logging in users in tests
  def log_in_as(user)
    post "/login", params: { session: { 
      username: user.username, 
      password: 'password' 
    }}
    follow_redirect!
  end
end
