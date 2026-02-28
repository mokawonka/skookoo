require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  
  # Fix ChromeDriver version compatibility for GitHub Actions
  before_setup do
    Webdrivers::Chromedriver.required_version = "120.0.6099.109"
  end
end
