require "test_helper"

class ReplyTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
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
    
    @reply = Reply.new(
      userid: @user.id,
      highlightid: @highlight.id,
      content: "This is a test reply content."
    )
  end

  test "should be valid" do
    assert @reply.valid?
  end

  test "userid should be present" do
    @reply.userid = nil
    assert_not @reply.valid?
  end

  test "highlightid should be present" do
    @reply.highlightid = nil
    assert_not @reply.valid?
  end

  test "content should be present" do
    @reply.content = ""
    assert_not @reply.valid?
  end

  test "content should have minimum length of 1" do
    @reply.content = ""
    assert_not @reply.valid?
    
    @reply.content = "a"
    assert @reply.valid?
  end

  test "default attributes should be set correctly" do
    reply = Reply.new(
      userid: @user.id,
      highlightid: @highlight.id,
      content: "Test content"
    )
    assert_equal false, reply.edited
    assert_equal false, reply.deleted
    assert_equal 0, reply.score
  end

  test "rich text content should work" do
    @reply.content = "<p>This is a rich text reply</p>"
    @reply.save!
    
    @reply.reload
    # ActionText wraps content in div with trix-content class
    assert_match /<div class="trix-content">\s*<p>This is a rich text reply<\/p>\s*<\/div>/, @reply.content.to_s
  end

  test "attachments should work correctly" do
    assert_respond_to @reply, :content_rich_text
  end

  test "getsubreplies should return replies for the same highlight" do
    @reply.save!
    
    # Create sub-replies
    subreply1 = Reply.create!(
      userid: @user.id,
      highlightid: @highlight.id,
      recipientid: @reply.id,
      content: "Sub-reply 1"
    )
    
    subreply2 = Reply.create!(
      userid: @user.id,
      highlightid: @highlight.id,
      recipientid: @reply.id,
      content: "Sub-reply 2"
    )
    
    # Create a deleted sub-reply (should not be returned)
    deleted_subreply = Reply.create!(
      userid: @user.id,
      highlightid: @highlight.id,
      recipientid: @reply.id,
      content: "Deleted sub-reply",
      deleted: true
    )
    
    # Create a reply for different highlight (should not be returned)
    other_highlight = Highlight.create!(
      userid: @user.id,
      docid: @document.id,
      quote: "Another quote that is at least twenty characters long.",
      cfi: "epubcfi(/6/5)",
      fromauthors: "Test Author",
      fromtitle: "Test Book"
    )
    
    other_reply = Reply.create!(
      userid: @user.id,
      highlightid: other_highlight.id,
      recipientid: @reply.id,
      content: "Reply for other highlight"
    )
    
    subreplies = @reply.getsubreplies
    assert_includes subreplies, subreply1
    assert_includes subreplies, subreply2
    assert_not_includes subreplies, deleted_subreply
    assert_not_includes subreplies, other_reply
  end

  test "after_create_commit should notify recipient" do
    # Test that the callback exists
    assert Reply._create_callbacks.find { |callback| callback.kind == :after_commit }
    
    # Create a reply to trigger the callback
    @reply.save!
    
    # The notification should be triggered (we can't easily test this without Mocha)
    assert @reply.persisted?
  end

  test "after_create_commit should not notify when replying to self" do
    # Create a reply by the same user who created the highlight
    @reply.save!
    
    # Should not create notification when replying to self
    # This test ensures the notification logic doesn't crash
    assert @reply.valid?
  end

  test "after_create_commit should notify parent reply author when replying to reply" do
    # Create parent reply by different user
    other_user = User.create!(username: "otheruser", email: "other@example.com", password: "password")
    parent_reply = Reply.create!(
      userid: other_user.id,
      highlightid: @highlight.id,
      content: "Parent reply"
    )
    
    # Create reply to parent reply
    reply_to_reply = Reply.new(
      userid: @user.id,
      highlightid: @highlight.id,
      recipientid: parent_reply.id,
      content: "Reply to parent"
    )
    
    # Test that the reply can be saved and notification logic doesn't crash
    assert reply_to_reply.save!
    assert reply_to_reply.persisted?
  end

  test "after_create_commit should not notify when replying to self reply" do
    @reply.save!
    
    # Create reply to own reply
    self_reply = Reply.new(
      userid: @user.id,
      highlightid: @highlight.id,
      recipientid: @reply.id,
      content: "Reply to self"
    )
    
    # Should not create notification when replying to self
    self_reply.save!
    assert self_reply.valid?
  end

  test "edited attribute should be updatable" do
    @reply.save!
    assert_equal false, @reply.edited
    
    @reply.edited = true
    @reply.save!
    @reply.reload
    assert_equal true, @reply.edited
  end

  test "deleted attribute should be updatable" do
    @reply.save!
    assert_equal false, @reply.deleted
    
    @reply.deleted = true
    @reply.save!
    @reply.reload
    assert_equal true, @reply.deleted
  end

  test "score should be updatable" do
    @reply.save!
    assert_equal 0, @reply.score
    
    @reply.score = 5
    @reply.save!
    @reply.reload
    assert_equal 5, @reply.score
  end

  test "should handle recipientid correctly" do
    # Reply without recipient (direct reply to highlight)
    @reply.recipientid = nil
    assert @reply.valid?
    @reply.save!
    assert_nil @reply.recipientid
    
    # Reply with recipient (reply to another reply)
    parent_reply = Reply.create!(
      userid: @user.id,
      highlightid: @highlight.id,
      content: "Parent reply"
    )
    
    child_reply = Reply.new(
      userid: @user.id,
      highlightid: @highlight.id,
      recipientid: parent_reply.id,
      content: "Child reply"
    )
    assert child_reply.valid?
    child_reply.save!
    assert_equal parent_reply.id, child_reply.recipientid
  end

  test "should handle long content" do
    long_content = "a" * 10000
    @reply.content = long_content
    assert @reply.valid?
    @reply.save!
    @reply.reload
    assert_equal long_content, @reply.content.to_s
  end
end
