require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @other_user = User.create!(username: "otheruser", email: "other@example.com", password: "password")
  end

  test "should get new when not logged in" do
    get signup_path
    assert_response :success
    assert_select 'form[action="/users"]'
  end

  test "should redirect new when logged in" do
    log_in_as(@user)
    get signup_path
    assert_redirected_to mysettings_path
  end

  test "should create user with valid attributes" do
    assert_difference('User.count', 1) do
      assert_difference('Subscription.count', 1) do
        post users_path, params: { user: { 
          username: "newuser", 
          email: "new@example.com", 
          password: "password",
          password_confirmation: "password"
        }}
      end
    end
    
    assert_redirected_to documents_path
    assert_equal "Welcome! Your account is ready.", flash[:notice]
    assert_equal session[:user_id], User.find_by(username: "newuser").id
  end

  test "should not create user with invalid attributes" do
    assert_no_difference('User.count') do
      post users_path, params: { user: { 
        username: "", 
        email: "invalid", 
        password: "short",
        password_confirmation: "mismatch"
      }}
    end
    
    assert_redirected_to signup_path
    assert_not_nil flash[:alert]
  end

  test "should show user profile" do
    get user_path(@user.username)
    assert_response :success
    assert_select 'h1', text: @user.username
  end

  test "should redirect when user not found" do
    get user_path("nonexistent")
    assert_redirected_to root_path
    assert_equal "User not found", flash[:alert]
  end

  test "should get edit when logged in as correct user" do
    log_in_as(@user)
    get edit_user_path(@user)
    assert_response :success
    assert_select 'form[action="/users/' + @user.id.to_s + '"]'
  end

  test "should redirect edit when not logged in" do
    get edit_user_path(@user)
    assert_redirected_to root_path
  end

  test "should update user with valid attributes" do
    log_in_as(@user)
    patch user_path(@user), params: { user: { 
      email: "updated@example.com",
      username: "updateduser"
    }}
    
    assert_response :success
    assert_equal "Changes saved", flash.now[:notice]
    @user.reload
    assert_equal "updated@example.com", @user.email
    assert_equal "updateduser", @user.username
  end

  test "should not update user with invalid attributes" do
    log_in_as(@user)
    patch user_path(@user), params: { user: { 
      email: "",
      username: ""
    }}
    
    assert_response :success
    assert_not_nil flash.now[:alert]
  end

  test "should update data via JS" do
    log_in_as(@user)
    patch update_data_user_path(@user), params: { user: { 
      darkmode: true,
      font: "Arial"
    }}, xhr: true
    
    assert_response :success
    @user.reload
    assert_equal true, @user.darkmode
    assert_equal "Arial", @user.font
  end

  test "should update profile via JS" do
    log_in_as(@user)
    patch update_profile_user_path(@user), params: { user: { 
      bio: "New bio",
      location: "New location"
    }}, xhr: true
    
    assert_response :success
    @user.reload
    assert_equal "New bio", @user.bio
    assert_equal "New location", @user.location
  end

  test "should update votes via JS" do
    log_in_as(@user)
    patch update_votes_user_path(@user), params: { 
      user: { "123" => "1", "456" => "-1" }
    }, xhr: true
    
    assert_response :success
    @user.reload
    assert_equal "1", @user.votes["123"]
    assert_equal "-1", @user.votes["456"]
  end

  test "should handle vote toggling correctly" do
    log_in_as(@user)
    @user.votes = { "123" => "1" }
    @user.save!
    
    # Toggle upvote to remove
    patch update_votes_user_path(@user), params: { 
      user: { "123" => "1" }
    }, xhr: true
    
    @user.reload
    assert_nil @user.votes["123"]
  end

  test "should update font via JS" do
    log_in_as(@user)
    patch update_font_user_path(@user), params: { font: "Times New Roman" }, xhr: true
    
    assert_response :success
    @user.reload
    assert_equal "Times New Roman", @user.font
  end

  test "should update hooked highlight via JS" do
    log_in_as(@user)
    patch update_hooked_user_path(@user), params: { 
      user: { hooked: "123" }
    }, xhr: true
    
    assert_response :success
    @user.reload
    assert_equal "123", @user.hooked
  end

  test "should increment mana via JS" do
    log_in_as(@user)
    original_mana = @user.mana
    
    post plusonemana_user_path(@user), xhr: true
    assert_response :success
    
    @user.reload
    assert_equal original_mana + 1, @user.mana
  end

  test "should decrement mana via JS" do
    log_in_as(@user)
    original_mana = @user.mana
    
    post minusonemana_user_path(@user), xhr: true
    assert_response :success
    
    @user.reload
    assert_equal original_mana - 1, @user.mana
  end

  test "should add two mana via JS" do
    log_in_as(@user)
    original_mana = @user.mana
    
    post plustwomana_user_path(@user), xhr: true
    assert_response :success
    
    @user.reload
    assert_equal original_mana + 2, @user.mana
  end

  test "should subtract two mana via JS" do
    log_in_as(@user)
    original_mana = @user.mana
    
    post minustwomana_user_path(@user), xhr: true
    assert_response :success
    
    @user.reload
    assert_equal original_mana - 2, @user.mana
  end

  test "should switch dark mode via JS" do
    log_in_as(@user)
    @user.update!(darkmode: false)
    
    post switch_mode_user_path(@user), xhr: true
    assert_response :success
    
    @user.reload
    assert_equal true, @user.darkmode
  end

  test "should follow public user via JS" do
    log_in_as(@user)
    @other_user.update!(private_profile: false)
    
    post follow_user_path(@other_user), xhr: true
    assert_response :success
    
    @user.reload
    @other_user.reload
    assert_includes @user.following, @other_user.id
    assert_includes @other_user.followers, @user.id
  end

  test "should request to follow private user via JS" do
    log_in_as(@user)
    @other_user.update!(private_profile: true)
    
    post follow_user_path(@other_user), xhr: true
    assert_response :success
    
    @other_user.reload
    assert_includes @other_user.pending_follow_requests, @user.id
    assert_equal "Follow request sent and is pending approval", flash.now[:notice]
  end

  test "should not allow self-follow" do
    log_in_as(@user)
    
    post follow_user_path(@user), xhr: true
    assert_response :success
    
    @user.reload
    assert_not_includes @user.following, @user.id
  end

  test "should unfollow user via JS" do
    log_in_as(@user)
    @user.following = [@other_user.id]
    @user.save!
    @other_user.followers = [@user.id]
    @other_user.save!
    
    post unfollow_user_path(@other_user), xhr: true
    assert_response :success
    
    @user.reload
    @other_user.reload
    assert_not_includes @user.following, @other_user.id
    assert_not_includes @other_user.followers, @user.id
  end

  test "should approve follow request via JS" do
    log_in_as(@other_user)
    @other_user.pending_follow_requests = [@user.id]
    @other_user.save!
    
    post approve_follow_request_user_path(@other_user), params: { 
      follower_id: @user.id 
    }, xhr: true
    
    assert_response :success
    @other_user.reload
    @user.reload
    
    assert_not_includes @other_user.pending_follow_requests, @user.id
    assert_includes @other_user.followers, @user.id
    assert_includes @user.following, @other_user.id
  end

  test "should reject follow request via JS" do
    log_in_as(@other_user)
    @other_user.pending_follow_requests = [@user.id]
    @other_user.save!
    
    post reject_follow_request_user_path(@other_user), params: { 
      follower_id: @user.id 
    }, xhr: true
    
    assert_response :success
    @other_user.reload
    
    assert_not_includes @other_user.pending_follow_requests, @user.id
    assert_not_includes @other_user.followers, @user.id
  end

  test "should show follow requests via JS" do
    log_in_as(@other_user)
    @other_user.pending_follow_requests = [@user.id]
    @other_user.save!
    
    get show_follow_requests_user_path(@other_user), xhr: true
    assert_response :success
  end

  test "should show user replies via JS" do
    get show_replies_user_path(@user), xhr: true
    assert_response :success
  end

  test "should show following via JS" do
    @user.following = [@other_user.id]
    @user.save!
    
    get show_following_user_path(@user), xhr: true
    assert_response :success
  end

  test "should show followers via JS" do
    @user.followers = [@other_user.id]
    @user.save!
    
    get show_followers_user_path(@user), xhr: true
    assert_response :success
  end

  test "should destroy user account" do
    log_in_as(@user)
    
    assert_difference('User.count', -1) do
      delete user_path(@user)
    end
    
    assert_redirected_to root_path
    assert_equal "Account deleted", flash.now[:notice]
    assert_nil session[:user_id]
  end

  test "should soft-delete replies when user is destroyed" do
    log_in_as(@user)
    reply = Reply.create!(userid: @user.id, highlightid: 1, content: "Test reply")
    
    delete user_path(@user)
    
    reply.reload
    assert_equal true, reply.deleted
  end

  private

  def log_in_as(user)
    post "/login", params: { session: { 
      username: user.username, 
      password: 'password' 
    }}
  end
end
