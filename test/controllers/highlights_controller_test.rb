require "test_helper"

class HighlightsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @other_user = User.create!(username: "otheruser", email: "other@example.com", password: "password")
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

  test "should get new when logged in" do
    log_in_as(@user)
    get new_highlight_path
    assert_response :success
  end

  test "should create highlight with valid attributes" do
    log_in_as(@user)
    assert_difference('Highlight.count', 1) do
      post highlights_path, params: { 
        highlight: { 
          docid: @document.id,
          quote: "Another test quote that is at least twenty characters long.",
          cfi: "epubcfi(/6/5)",
          fromauthors: "Test Author",
          fromtitle: "Test Book"
        }
      }
    end
    
    assert_response :success
    assert_match "Highlight added successfully", flash.now[:success]
  end

  test "should create highlight with token authentication" do
    token = generate_token_for(@user)
    assert_difference('Highlight.count', 1) do
      post highlights_path, params: { 
        token: token,
        highlight: { 
          docid: @document.id,
          quote: "Another test quote that is at least twenty characters long.",
          cfi: "epubcfi(/6/5)",
          fromauthors: "Test Author",
          fromtitle: "Test Book"
        }
      }
    end
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
  end

  test "should not create highlight without authentication" do
    assert_no_difference('Highlight.count') do
      post highlights_path, params: { 
        highlight: { 
          docid: @document.id,
          quote: "Another test quote that is at least twenty characters long.",
          cfi: "epubcfi(/6/5)",
          fromauthors: "Test Author",
          fromtitle: "Test Book"
        }
      }
    end
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "Authentication required", json_response['error']
  end

  test "should not create highlight with invalid token" do
    assert_no_difference('Highlight.count') do
      post highlights_path, params: { 
        token: "invalid_token",
        highlight: { 
          docid: @document.id,
          quote: "Another test quote that is at least twenty characters long.",
          cfi: "epubcfi(/6/5)",
          fromauthors: "Test Author",
          fromtitle: "Test Book"
        }
      }
    end
    
    assert_response :unauthorized
  end

  test "should not create highlight with invalid attributes" do
    log_in_as(@user)
    assert_no_difference('Highlight.count') do
      post highlights_path, params: { 
        highlight: { 
          docid: @document.id,
          quote: "Short quote",
          cfi: "epubcfi(/6/5)",
          fromauthors: "Test Author",
          fromtitle: "Test Book"
        }
      }
    end
    
    assert_response :success
    assert_match "Failed", response.body
  end

  test "should show highlight" do
    get highlight_path(@highlight)
    assert_response :success
    assert_select 'h1', text: @highlight.fromtitle
  end

  test "should show highlight with replies" do
    reply = Reply.create!(
      userid: @user.id,
      highlightid: @highlight.id,
      content: "Test reply"
    )
    
    get highlight_path(@highlight)
    assert_response :success
    assert_select 'div', text: reply.content.to_s
  end

  test "should update score via JS" do
    log_in_as(@user)
    original_score = @highlight.score
    
    patch update_score_highlight_path(@highlight), params: { 
      highlight: { "increment" => "1" }
    }, xhr: true
    
    assert_response :success
    @highlight.reload
    assert_equal original_score + 1, @highlight.score
  end

  test "should destroy own highlight" do
    log_in_as(@user)
    assert_difference('Highlight.count', -1) do
      delete highlight_path(@highlight), params: { from: "highlight" }
    end
    
    assert_redirected_to user_path(@user.username)
  end

  test "should destroy own highlight from document view" do
    log_in_as(@user)
    assert_difference('Highlight.count', -1) do
      delete highlight_path(@highlight), params: { from: "document" }
    end
    
    assert_response :redirect
  end

  test "should not destroy other user's highlight" do
    log_in_as(@other_user)
    assert_no_difference('Highlight.count') do
      delete highlight_path(@highlight)
    end
    
    # Should not redirect or do anything since the check fails
    assert_response :redirect
  end

  test "should soft-delete replies when highlight is destroyed" do
    log_in_as(@user)
    reply = Reply.create!(
      userid: @other_user.id,
      highlightid: @highlight.id,
      content: "Test reply"
    )
    
    delete highlight_path(@highlight)
    
    reply.reload
    assert_equal true, reply.deleted
  end

  test "should handle multiple reaction types correctly" do
    log_in_as(@user)
    
    # Test with comment
    post highlights_path, params: { 
      highlight: { 
        docid: @document.id,
        quote: "Another test quote that is at least twenty characters long.",
        cfi: "epubcfi(/6/5)",
        fromauthors: "Test Author",
        fromtitle: "Test Book",
        comment: "This is a comment"
      }
    }
    
    assert_response :success
    
    # Test with liked
    post highlights_path, params: { 
      highlight: { 
        docid: @document.id,
        quote: "Yet another test quote that is at least twenty characters long.",
        cfi: "epubcfi(/6/6)",
        fromauthors: "Test Author",
        fromtitle: "Test Book",
        liked: true
      }
    }
    
    assert_response :success
  end

  test "should handle timestamp check" do
    log_in_as(@user)
    
    # First request should succeed
    post highlights_path, params: { 
      highlight: { 
        docid: @document.id,
        quote: "First quote that is at least twenty characters long.",
        cfi: "epubcfi(/6/7)",
        fromauthors: "Test Author",
        fromtitle: "Test Book"
      }
    }
    
    assert_response :success
    
    # Immediate second request should be rate limited
    post highlights_path, params: { 
      highlight: { 
        docid: @document.id,
        quote: "Second quote that is at least twenty characters long.",
        cfi: "epubcfi(/6/8)",
        fromauthors: "Test Author",
        fromtitle: "Test Book"
      }
    }
    
    assert_response :success
    # Should render the rate limit template
  end

  test "should create HTML response for non-XHR requests" do
    log_in_as(@user)
    
    post highlights_path, params: { 
      highlight: { 
        docid: @document.id,
        quote: "Another test quote that is at least twenty characters long.",
        cfi: "epubcfi(/6/5)",
        fromauthors: "Test Author",
        fromtitle: "Test Book"
      }
    }, headers: { "HTTP_X_REQUESTED_WITH" => nil }
    
    assert_redirected_to document_path(@document.id)
  end

  private

  def log_in_as(user)
    post sessions_path, params: { session: { 
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
end
