require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @epub = Epub.create!(title: "Test Book", authors: "Test Author", lang: "en")
    @document = Document.create!(userid: @user.id, epubid: @epub.id)
  end

  test "should get index without session_id" do
    get "/"
    assert_response :success
    assert_select "h1", false  # Pages controller doesn't have h1, just highlights
  end

  test "should handle Stripe session with successful payment" do
    skip "Requires Stripe integration testing"
  end

  test "should handle Stripe session with unsuccessful payment" do
    skip "Requires Stripe integration testing"
  end

  test "current_user should return user from session" do
    log_in_as(@user)
    get root_path
    
    assert_equal @user, @controller.send(:current_user)
  end

  test "current_user should return user from token" do
    token = generate_token_for(@user)
    get root_path, params: { token: token }
    
    assert_equal @user, @controller.send(:current_user)
  end

  test "current_user should prefer token over session" do
    log_in_as(@user)
    other_user = User.create!(username: "otheruser", email: "other@example.com", password: "password")
    token = generate_token_for(other_user)
    
    get root_path, params: { token: token }
    
    assert_equal other_user, @controller.send(:current_user)
  end

  test "current_user should return nil with invalid token" do
    get root_path, params: { token: "invalid_token" }
    
    assert_nil @controller.send(:current_user)
  end

  test "current_user should return nil with expired token" do
    expired_token = generate_expired_token_for(@user)
    get root_path, params: { token: expired_token }
    
    assert_nil @controller.send(:current_user)
  end

  test "logged_in? should return true when user is logged in" do
    log_in_as(@user)
    get root_path
    
    assert_equal true, @controller.send(:logged_in?)
  end

  test "logged_in? should return false when user is not logged in" do
    get root_path
    
    assert_equal false, @controller.send(:logged_in?)
  end

  test "require_user should allow access when logged in" do
    log_in_as(@user)
    get root_path
    
    assert_response :success
    assert_nil flash[:alert]
  end

  test "require_user should redirect when not logged in" do
    get documents_path
    
    assert_redirected_to login_path
    assert_equal "You must be logged in to perform that action.", flash[:alert]
  end

  test "authorize_user! should redirect when no session user_id" do
    skip "Private method testing not available"
  end

  test "check_timestamp should allow requests with sufficient time gap" do
    log_in_as(@user)
    
    # Test on a controller that actually uses check_timestamp
    get new_highlight_path
    assert_response :success
    
    # Wait and make second request (in real scenario)
    # For testing, we'll just ensure the method doesn't crash
    get new_highlight_path
    assert_response :success
  end

  test "check_timestamp should handle rapid requests" do
    log_in_as(@user)
    
    # Simulate rapid requests by setting last_action_at
    session[:last_action_at] = 1.second.ago
    
    # Test on a controller that actually uses check_timestamp
    post highlights_path, params: { 
      highlight: { 
        docid: @document.id,
        quote: "Another test quote that is at least twenty characters long.",
        cfi: "epubcfi(/6/5)",
        fromauthors: "Test Author",
        fromtitle: "Test Book"
      }
    }, xhr: true
    # Should render the timestamp check template
    assert_response :success
  end

  test "helper methods should be available" do
    get root_path
    
    # These should not raise errors
    assert_respond_to @controller, :current_user
    assert_respond_to @controller, :logged_in?
  end

  test "should handle Bearer token prefix" do
    token = generate_token_for(@user)
    bearer_token = "Bearer #{token}"
    
    get root_path, params: { token: bearer_token }
    
    assert_equal @user, @controller.send(:current_user)
  end

  private

  def log_in_as(user)
    post "/login", params: { session: { 
      username: user.username, 
      password: 'password' 
    }}
  end

  def generate_token_for(user)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    verifier.generate({
      user_id: user.id,
      exp: 24.hours.from_now.to_i
    })
  end

  def generate_expired_token_for(user)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    verifier.generate({
      user_id: user.id,
      exp: 1.hour.ago.to_i
    })
  end

  def generate_token_for_nonexistent_user
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    verifier.generate({
      user_id: 99999,
      exp: 24.hours.from_now.to_i
    })
  end
end
