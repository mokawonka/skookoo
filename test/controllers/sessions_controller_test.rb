require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "should create session with valid credentials" do
    post sessions_path, params: { session: { 
      username: @user.username, 
      password: 'password' 
    }}
    
    assert_redirected_to documents_path
    assert_equal "Logged in successfully.", flash[:notice]
    assert_equal @user.id, session[:user_id]
  end

  test "should create session with case-insensitive username" do
    post sessions_path, params: { session: { 
      username: @user.username.upcase, 
      password: 'password' 
    }}
    
    assert_redirected_to documents_path
    assert_equal @user.id, session[:user_id]
  end

  test "should not create session with invalid username" do
    post sessions_path, params: { session: { 
      username: "wronguser", 
      password: 'password' 
    }}
    
    assert_redirected_to login_path
    assert_equal "Invalid username or password.", flash[:alert]
    assert_nil session[:user_id]
  end

  test "should not create session with invalid password" do
    post sessions_path, params: { session: { 
      username: @user.username, 
      password: 'wrongpassword' 
    }}
    
    assert_redirected_to login_path
    assert_equal "Invalid username or password.", flash[:alert]
    assert_nil session[:user_id]
  end

  test "should not create session with blank credentials" do
    post sessions_path, params: { session: { 
      username: "", 
      password: "" 
    }}
    
    assert_redirected_to login_path
    assert_equal "Invalid username or password.", flash[:alert]
    assert_nil session[:user_id]
  end

  test "should redirect to return_to URL if present" do
    session[:return_to] = "/some/path"
    
    post sessions_path, params: { session: { 
      username: @user.username, 
      password: 'password' 
    }}
    
    assert_redirected_to "/some/path"
    assert_nil session[:return_to]
  end

  test "should redirect to default path if no return_to URL" do
    post sessions_path, params: { session: { 
      username: @user.username, 
      password: 'password' 
    }}
    
    assert_redirected_to documents_path
  end

  test "should destroy session" do
    log_in_as(@user)
    
    delete session_path(session[:user_id])
    
    assert_redirected_to root_path
    assert_equal "You have been logged out.", flash[:notice]
    assert_nil session[:user_id]
  end

  test "should destroy session even when not logged in" do
    delete session_path(1)
    
    assert_redirected_to root_path
    assert_equal "You have been logged out.", flash[:notice]
    assert_nil session[:user_id]
  end

  test "should handle session destruction with flash" do
    log_in_as(@user)
    
    delete session_path(session[:user_id])
    
    follow_redirect!
    assert_match "You have been logged out", response.body
  end

  private

  def log_in_as(user)
    post sessions_path, params: { session: { 
      username: user.username, 
      password: 'password' 
    }}
  end
end
