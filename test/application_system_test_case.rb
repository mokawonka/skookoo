require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  # Fix Chromedriver auto-download failure in GitHub Actions
  # Use a recent stable version that always has a matching driver
  # As of 2026: 132.x is widely available and stable
  before_setup do
    # Option A: Hard pin a known-good stable version (recommended for CI stability)
    Webdrivers::Chromedriver.required_version = "132.0.6834.159"   # ← works in Feb 2026 CI

    # Option B: Let webdrivers use the latest *available* driver (less strict, but safer than auto-detect)
    # Webdrivers::Chromedriver.required_version = Webdrivers::Chromedriver.latest_version(within: 3.months.ago..Date.today)

    # Optional: force headless mode in CI (faster, no GUI needed)
    if ENV["CI"]
      Capybara.server = :puma, { Silent: true }
      Capybara.default_max_wait_time = 10
    end
  end
end