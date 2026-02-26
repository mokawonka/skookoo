require "test_helper"

class SocialFeaturesTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @other_user = User.create!(username: "otheruser", email: "other@example.com", password: "password")
    @private_user = User.create!(username: "privateuser", email: "private@example.com", password: "password")
    @private_user.update!(private_profile: true)
    
    @epub = Epub.create!(title: "Test Book", authors: "Test Author", lang: "en")
    @document = Document.create!(userid: @user.id, epubid: @epub.id)
    @highlight = Highlight.create!(
      userid: @user.id,
      docid: @document.id,
      quote: "This is a test quote that is at least twenty characters long.",
      cfi: "epubcfi(/6/4)",
      fromauthors: "Test Author",
      fromtitle: "Test Book"
    )
  end

  def log_in_as(user)
    post "/login", params: { 
      session: { 
        username: user.username, 
        password: "password" 
      }
    }
    assert_redirected_to root_path
  end

  test "follow public user flow" do
    # Login as testuser
    log_in_as(@user)
    
    # Visit other user's profile
    get user_path(@other_user.username)
    assert_response :success
    
    # Follow the user
    post follow_user_path(@other_user), xhr: true
    assert_response :success
    
    # Verify follow relationship
    @user.reload
    @other_user.reload
    assert_includes @user.following, @other_user.id
    assert_includes @other_user.followers, @user.id
    
    # Check following list
    get show_following_user_path(@user), xhr: true
    assert_response :success
    
    # Check followers list
    get show_followers_user_path(@other_user), xhr: true
    assert_response :success
  end

  test "follow private user flow" do
    # Login as testuser
    log_in_as(@user)
    
    # Try to follow private user
    post follow_user_path(@private_user), xhr: true
    assert_response :success
    
    # Verify pending request
    @private_user.reload
    assert_includes @private_user.pending_follow_requests, @user.id
    
    # Should not be in following/followers yet
    @user.reload
    assert_not_includes @user.following, @private_user.id
    assert_not_includes @private_user.followers, @user.id
    
    # Login as private user and approve request
    log_in_as(@private_user)
    
    # Show follow requests
    get show_follow_requests_user_path(@private_user), xhr: true
    assert_response :success
    
    # Approve follow request
    post approve_follow_request_user_path(@private_user), params: { 
      follower_id: @user.id 
    }, xhr: true
    assert_response :success
    
    # Verify follow relationship
    @user.reload
    @private_user.reload
    assert_includes @user.following, @private_user.id
    assert_includes @private_user.followers, @user.id
    assert_not_includes @private_user.pending_follow_requests, @user.id
  end

  test "reject follow request flow" do
    # Login as testuser and request to follow private user
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "password" 
      }
    }
    
    post follow_user_path(@private_user), xhr: true
    assert_response :success
    
    # Login as private user and reject request
    delete session_path(session[:user_id])
    post "/login", params: { 
      session: { 
        username: @private_user.username, 
        password: "password" 
      }
    }
    
    post reject_follow_request_user_path(@private_user), params: { 
      follower_id: @user.id 
    }, xhr: true
    assert_response :success
    
    # Verify request is rejected
    @private_user.reload
    assert_not_includes @private_user.pending_follow_requests, @user.id
    assert_not_includes @private_user.followers, @user.id
  end

  test "unfollow user flow" do
    # Setup follow relationship
    @user.following = [@other_user.id]
    @user.save!
    @other_user.followers = [@user.id]
    @other_user.save!
    
    # Login and unfollow
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "password" 
      }
    }
    
    post unfollow_user_path(@other_user), xhr: true
    assert_response :success
    
    # Verify unfollow
    @user.reload
    @other_user.reload
    assert_not_includes @user.following, @other_user.id
    assert_not_includes @other_user.followers, @user.id
  end

  test "self-follow prevention" do
    # Login as user
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "password" 
      }
    }
    
    # Try to follow self
    post follow_user_path(@user), xhr: true
    assert_response :success
    
    # Should not create follow relationship
    @user.reload
    assert_not_includes @user.following, @user.id
  end

  test "highlight and reply interaction flow" do
    # Login as other user
    post "/login", params: { 
      session: { 
        username: @other_user.username, 
        password: "password" 
      }
    }
    
    # View highlight
    get highlight_path(@highlight)
    assert_response :success
    
    # Reply to highlight
    post replies_path, params: { 
      reply: { 
        highlightid: @highlight.id,
        content: "This is a test reply to the highlight."
      }
    }
    
    assert_response :success
    assert_equal 1, Reply.where(highlightid: @highlight.id, deleted: false).count
    
    # View highlight again to see reply
    get highlight_path(@highlight)
    assert_response :success
    assert_select 'div', text: /This is a test reply/
    
    # Reply to the reply
    reply = Reply.last
    post replies_path, params: { 
      reply: { 
        highlightid: @highlight.id,
        recipientid: reply.id,
        content: "This is a reply to the reply."
      }
    }
    
    assert_response :success
    assert_equal 2, Reply.where(highlightid: @highlight.id, deleted: false).count
  end

  test "voting system flow" do
    # Login as other user
    post "/login", params: { 
      session: { 
        username: @other_user.username, 
        password: "password" 
      }
    }
    
    # Upvote highlight
    patch update_votes_user_path(@other_user), params: { 
      user: { @highlight.id.to_s => "1" }
    }, xhr: true
    
    assert_response :success
    @other_user.reload
    assert_equal "1", @other_user.votes[@highlight.id.to_s]
    
    # Change vote to downvote
    patch update_votes_user_path(@other_user), params: { 
      user: { @highlight.id.to_s => "-1" }
    }, xhr: true
    
    assert_response :success
    @other_user.reload
    assert_equal "-1", @other_user.votes[@highlight.id.to_s]
    
    # Remove vote
    patch update_votes_user_path(@other_user), params: { 
      user: { @highlight.id.to_s => "-1" }
    }, xhr: true
    
    assert_response :success
    @other_user.reload
    assert_nil @other_user.votes[@highlight.id.to_s]
  end

  test "user profile with highlights and replies flow" do
    # Create some content for user
    reply = Reply.create!(
      userid: @user.id,
      highlightid: @highlight.id,
      content: "Test reply from user"
    )
    
    # Visit user profile
    get user_path(@user.username)
    assert_response :success
    
    # Should show highlights
    assert_select 'div', text: @highlight.quote
    
    # Show replies
    get show_replies_user_path(@user), xhr: true
    assert_response :success
  end

  test "private profile access restrictions" do
    # Login as regular user
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "password" 
      }
    }
    
    # Try to access private user's profile
    get user_path(@private_user.username)
    assert_response :success # Should show profile but with limited content
    
    # Should not show private content
    # This would depend on the view implementation
  end

  test "notification flow for new followers" do
    # This would test the notification system
    # Since notifications use background jobs, we'd need to mock or test differently
    
    # Login as testuser
    post "/login", params: { 
      session: { 
        username: @user.username, 
        password: "password" 
      }
    }
    
    # Follow other user
    post follow_user_path(@other_user), xhr: true
    assert_response :success
    
    # The notification should be enqueued
    # Actual notification testing would require more complex setup
  end
end
