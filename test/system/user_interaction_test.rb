require "application_system_test_case"

class UserInteractionTest < ApplicationSystemTestCase
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

  test "user registration and login flow" do
    visit signup_path
    
    # Fill registration form
    fill_in "user_username", with: "newuser"
    fill_in "user_email", with: "newuser@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    
    click_button "Sign Up"
    
    # Should be redirected to documents
    assert_text "Welcome"
    assert_current_path documents_path
    
    # Test logout
    click_on "Logout"
    assert_text "logged out"
    assert_current_path root_path
    
    # Test login
    visit login_path
    fill_in "session_username", with: "newuser"
    fill_in "session_password", with: "password123"
    click_button "Log In"
    
    assert_text "Logged in successfully"
    assert_current_path documents_path
  end

  test "dark mode toggle" do
    log_in_as(@user)
    visit root_path
    
    # Toggle dark mode
    find("#dark-mode-toggle").click
    
    # Should reload page with dark mode
    assert_no_selector "#dark-mode-toggle" # Page reloads
    visit root_path
    
    # Check if dark mode is applied (would depend on CSS implementation)
    # This is a basic test - actual implementation might differ
  end

  test "follow and unfollow users" do
    log_in_as(@user)
    visit user_path(@other_user.username)
    
    # Follow user
    click_on "Follow"
    
    # Should show success message (via JS)
    assert_text "Following"
    
    # Check following list
    visit user_path(@user.username)
    click_on "Following"
    
    # Should show followed user
    assert_text @other_user.username
    
    # Unfollow user
    visit user_path(@other_user.username)
    click_on "Unfollow"
    
    # Should update via JS
    assert_text "Follow"
  end

  test "private profile follow request flow" do
    log_in_as(@user)
    visit user_path(@private_user.username)
    
    # Request to follow private user
    click_on "Follow"
    
    # Should show pending message
    assert_text "Follow request sent"
    
    # Login as private user
    click_on "Logout"
    log_in_as(@private_user)
    
    # Check follow requests modal
    click_on "Follow Requests"
    
    # Should show pending request
    assert_text @user.username
    
    # Approve request
    within ".follow-request-#{@user.id}" do
      click_on "Approve"
    end
    
    # Should update via JS
    assert_no_text @user.username
    
    # Verify follow relationship
    click_on "Logout"
    log_in_as(@user)
    visit user_path(@private_user.username)
    
    assert_text "Following"
  end

  test "highlight creation and interaction" do
    log_in_as(@user)
    visit document_path(@document.id)
    
    # Create highlight (this would depend on the actual UI implementation)
    # Assuming there's a way to select text and create highlights
    
    # Test voting on highlight
    visit highlight_path(@highlight)
    
    # Upvote
    find(".upvote-#{@highlight.id}").click
    # Should update via JS
    
    # Change to downvote
    find(".downvote-#{@highlight.id}").click
    # Should update via JS
    
    # Remove vote
    find(".upvote-#{@highlight.id}").click
    # Should update via JS
  end

  test "reply creation and interaction" do
    log_in_as(@other_user)
    visit highlight_path(@highlight)
    
    # Add reply
    fill_in "reply_content", with: "This is a test reply from the system test."
    click_on "Reply"
    
    # Should show reply via JS
    assert_text "This is a test reply from the system test"
    
    # Reply to the reply
    within ".reply-#{Reply.last.id}" do
      click_on "Reply"
      fill_in "reply_content", with: "This is a reply to the reply."
      click_on "Reply"
    end
    
    # Should show nested reply
    assert_text "This is a reply to the reply"
  end

  test "user profile editing" do
    log_in_as(@user)
    visit edit_user_path(@user)
    
    # Update basic info
    fill_in "user_bio", with: "Updated bio from system test"
    fill_in "user_location", with: "Test City"
    
    click_on "Save Changes"
    
    # Should show success message via JS
    assert_text "Changes saved"
    
    # Verify changes
    visit user_path(@user.username)
    assert_text "Updated bio from system test"
    assert_text "Test City"
  end

  test "font and display preferences" do
    log_in_as(@user)
    visit edit_user_path(@user)
    
    # Change font
    select "Arial", from: "user_font"
    click_on "Save Changes"
    
    # Should reload with new font
    assert_text "Changes saved"
    
    # Test dark mode toggle
    find("#dark-mode-toggle").click
    # Should reload with dark mode
  end

  test "mana system interaction" do
    log_in_as(@user)
    visit user_path(@user.username)
    
    # Test mana adjustments (assuming UI controls exist)
    initial_mana = @user.mana
    
    # Add mana
    find(".plus-one-mana").click
    # Should update via JS
    
    # Subtract mana
    find(".minus-one-mana").click
    # Should update via JS
    
    # Add two mana
    find(".plus-two-mana").click
    # Should update via JS
    
    # Subtract two mana
    find(".minus-two-mana").click
    # Should update via JS
  end

  test "highlight reactions" do
    log_in_as(@user)
    visit document_path(@document.id)
    
    # Test different reaction types
    # Comment reaction
    find(".add-comment").click
    fill_in "comment", with: "This is a comment reaction"
    click_on "Add Comment"
    
    # Like reaction
    find(".add-like").click
    
    # Emoji reaction (if available)
    find(".add-emoji").click
    find(".emoji-smile").click
    
    # GIF reaction (if available)
    find(".add-gif").click
    # Would depend on GIF selection UI
  end

  test "search functionality" do
    # Create searchable content
    Highlight.create!(
      userid: @user.id,
      docid: @document.id,
      quote: "Ruby programming is fun and educational",
      cfi: "epubcfi(/6/5)",
      fromauthors: "Ruby Author",
      fromtitle: "Ruby Programming Guide"
    )
    
    visit root_path
    
    # Test search
    fill_in "search", with: "Ruby"
    click_on "Search"
    
    # Should show search results
    assert_text "Ruby programming is fun"
    assert_text "Ruby Programming Guide"
  end

  test "responsive design elements" do
    log_in_as(@user)
    
    # Test mobile view
    resize_window_to(375, 667) # iPhone size
    visit root_path
    
    # Should show mobile navigation
    assert_selector ".mobile-nav"
    
    # Test tablet view
    resize_window_to(768, 1024) # iPad size
    visit root_path
    
    # Should adapt layout
    assert_selector ".tablet-layout"
    
    # Test desktop view
    resize_window_to(1200, 800) # Desktop size
    visit root_path
    
    # Should show desktop layout
    assert_selector ".desktop-layout"
  end

  test "error handling and validation messages" do
    visit signup_path
    
    # Submit empty form
    click_button "Sign Up"
    
    # Should show validation errors
    assert_text "can't be blank"
    assert_text "too short"
    
    # Try to create invalid highlight
    log_in_as(@user)
    visit document_path(@document.id)
    
    # Try to create short quote
    fill_in "quote", with: "Short"
    click_on "Create Highlight"
    
    # Should show error
    assert_text "at least 20 characters"
  end

  test "accessibility features" do
    log_in_as(@user)
    visit root_path
    
    # Test keyboard navigation
    find("nav").click
    press "Tab"
    # Should focus on next interactive element
    
    # Test ARIA labels
    assert_selector "[aria-label]"
    
    # Test skip links (if implemented)
    assert_selector ".skip-link"
  end

  private

  def log_in_as(user)
    visit login_path
    fill_in "session_username", with: user.username
    fill_in "session_password", with: "password"
    click_on "Log In"
  end

  def resize_window_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end
end
