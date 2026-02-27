require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "should get new" do
    log_in_as(@user)
    get subscriptions_new_url
    assert_response :success
  end

  test "should get create" do
    log_in_as(@user)
    get subscriptions_create_url
    # The create method redirects to Stripe for payment processing
    assert_response :redirect
    assert_match /stripe\.com/, response.location
  end
end
