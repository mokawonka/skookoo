require "test_helper"

class UserAuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "complete user registration and login flow" do
    # Visit signup page
    get signup_path
    assert_response :success
    assert_select 'form[action="/users"]'
    
    # Register new user
    post users_path, params: { 
      user: { 
        username: "newuser", 
        email: "new@example.com", 
        password: "password123",
        password_confirmation: "password123"
      }
    }
    
    follow_redirect!
    assert_equal documents_path, path
    assert_match "Welcome", flash[:notice]
    
    # Verify user is logged in
    get root_path
    assert_select "a[href='/logout']"
    
    # Logout
    delete session_path(session[:user_id])
    follow_redirect!
    assert_equal root_path, path
    assert_match "logged out", flash[:notice]
    
    # Login again
    post "/login", params: { 
      session: { 
        username: "newuser", 
        password: "password123" 
      }
    }
    
    follow_redirect!
    assert_equal documents_path, path
    assert_match "Logged in successfully", flash[:notice]
  end

  test "failed login flow" do
    # Try to login with wrong password
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "wrongpassword" 
      }
    }
    
    follow_redirect!
    assert_equal login_path, path
    assert_match "Invalid username or password", flash[:alert]
    
    # Try to login with wrong username
    post "/login", params: { 
      session: { 
        username: "wronguser", 
        password: "password" 
      }
    }
    
    follow_redirect!
    assert_equal login_path, path
    assert_match "Invalid username or password", flash[:alert]
  end

  test "protected routes require authentication" do
    protected_routes = [
      documents_path,
      new_highlight_path,
      edit_user_path(@user),
      mysettings_path
    ]
    
    protected_routes.each do |route|
      get route
      follow_redirect!
      assert_equal login_path, path
      assert_match "must be logged in", flash[:alert]
    end
  end

  test "token-based authentication flow" do
    # Generate token for user
    token = generate_token_for(@user)
    
    # Access protected route with token
    get documents_path, params: { token: token }
    assert_response :success
    
    # Create highlight with token
    post highlights_path, params: { 
      token: token,
      highlight: { 
        docid: 1, # Would need actual document
        quote: "Test quote that is at least twenty characters long.",
        cfi: "epubcfi(/6/4)",
        fromauthors: "Test Author",
        fromtitle: "Test Book"
      }
    }
    
    # Should succeed with token authentication
    assert_response :success
  end

  test "expired token should not authenticate" do
    expired_token = generate_expired_token_for(@user)
    
    get documents_path, params: { token: expired_token }
    follow_redirect!
    assert_equal login_path, path
  end

  test "session persistence across requests" do
    # Login
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "password" 
      }
    }
    
    # Verify session persists
    get root_path
    assert_equal @user.id, session[:user_id]
    
    # Access multiple protected pages
    get documents_path
    assert_response :success
    
    get edit_user_path(@user)
    assert_response :success
    
    # Session should still be valid
    assert_equal @user.id, session[:user_id]
  end

  test "user profile access flow" do
    # Login
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "password" 
      }
    }
    
    # Visit own profile
    get user_path(@user.username)
    assert_response :success
    assert_select 'h1', text: @user.username
    
    # Visit edit profile
    get edit_user_path(@user)
    assert_response :success
    assert_select 'form[action="/users/' + @user.id.to_s + '"]'
    
    # Update profile
    patch user_path(@user), params: { 
      user: { 
        bio: "New bio",
        location: "New location"
      }
    }
    
    assert_response :success
    assert_match "Changes saved", flash.now[:notice]
  end

  test "account deletion flow" do
    other_user = User.create!(username: "otheruser", email: "other@example.com", password: "password")
    
    # Create some content
    epub = Epub.create!(title: "Test Book", authors: "Test Author", lang: "en")
    document = Document.create!(userid: other_user.id, epubid: epub.id)
    highlight = Highlight.create!(
      userid: other_user.id,
      docid: document.id,
      quote: "Test quote that is at least twenty characters long.",
      cfi: "epubcfi(/6/4)",
      fromauthors: "Test Author",
      fromtitle: "Test Book"
    )
    reply = Reply.create!(
      userid: other_user.id,
      highlightid: highlight.id,
      content: "Test reply"
    )
    
    # Login as other user
    post "/login", params: { 
      session: { 
        username: other_user.username, 
        password: "password" 
      }
    }
    
    # Delete account
    delete user_path(other_user)
    follow_redirect!
    assert_equal root_path, path
    assert_match "Account deleted", flash[:notice]
    
    # Verify session is cleared
    assert_nil session[:user_id]
    
    # Verify content is soft-deleted
    reply.reload
    assert_equal true, reply.deleted
    
    # Verify user is deleted
    assert_not User.exists?(other_user.id)
  end

  private

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
end
