require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "should create session with valid credentials" do
    post "/login", params: { session: { 
      username: @user.username, 
      password: 'password' 
    }}
    
    assert_redirected_to documents_path
    assert_equal "Logged in successfully.", flash[:notice]
    assert_equal @user.id, session[:user_id]
  end

  test "should create session with case-insensitive username" do
    post "/login", params: { session: { 
      username: @user.username.upcase, 
      password: 'password' 
    }}
    
    assert_redirected_to documents_path
    assert_equal @user.id, session[:user_id]
  end

  test "should not create session with invalid username" do
    post "/login", params: { session: { 
      username: 'wronguser', 
      password: 'password' 
    }}
    
    assert_redirected_to login_path
    assert_match /Invalid username or password/, flash[:alert]
    assert_nil session[:user_id]
  end

  test "should not create session with invalid password" do
    post "/login", params: { session: { 
      username: @user.username, 
      password: 'wrongpassword' 
    }}
    
    assert_redirected_to login_path
    assert_match /Invalid username or password/, flash[:alert]
    assert_nil session[:user_id]
  end

  test "should not create session with blank credentials" do
    post "/login", params: { session: { 
      username: '', 
      password: '' 
    }}
    
    assert_redirected_to login_path
    assert_match /Invalid username or password/, flash[:alert]
    assert_nil session[:user_id]
  end

  test "should redirect to return_to URL if present" do
    post "/login", params: { session: { 
      username: @user.username, 
      password: 'password' 
    }}, headers: { "HTTP_REFERER" => "/some/path" }
    
    assert_redirected_to "/some/path"
  end

  test "should redirect to return_to URL from referer if present" do
    post "/login", params: { session: { 
      username: @user.username, 
      password: 'password' 
    }}, headers: { "HTTP_REFERER" => "/some/path" }
    
    assert_redirected_to "/some/path"
  end

  test "should destroy session" do
    log_in_as(@user)
    delete "/logout"
    
    assert_redirected_to root_path
    assert_equal "You have been logged out.", flash[:notice]
    assert_nil session[:user_id]
  end

  test "should destroy session even when not logged in" do
    delete "/logout"
    
    assert_redirected_to root_path
    assert_equal "You have been logged out.", flash[:notice]
    assert_nil session[:user_id]
  end

  test "should handle session destruction with flash" do
    log_in_as(@user)
    
    delete "/logout"
    
    follow_redirect!
    # Check that we're redirected to home page
    assert_equal root_path, path
  end
end
