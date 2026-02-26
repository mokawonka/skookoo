require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @epub = Epub.create!(title: "Test Book", authors: "Test Author", lang: "en")
    
    @document = Document.new(
      userid: @user.id,
      epubid: @epub.id
    )
  end

  test "should be valid" do
    assert @document.valid?
  end

  test "userid should be present" do
    @document.userid = nil
    assert_not @document.valid?
  end

  test "epubid should be present" do
    @document.epubid = nil
    assert_not @document.valid?
  end

  test "default attributes should be set correctly" do
    document = Document.new(userid: @user.id, epubid: @epub.id)
    assert_equal true, document.ispublic
    assert_equal 0.00000000, document.progress
    assert_equal 0, document.opened
  end

  test "belongs to epub should work" do
    @document.save!
    assert_equal @epub, @document.epub
  end

  test "progress should be updatable" do
    @document.save!
    @document.progress = 0.5
    @document.save!
    @document.reload
    assert_equal 0.5, @document.progress
  end

  test "opened should be updatable" do
    @document.save!
    @document.opened = 5
    @document.save!
    @document.reload
    assert_equal 5, @document.opened
  end

  test "ispublic should be updatable" do
    @document.save!
    @document.ispublic = false
    @document.save!
    @document.reload
    assert_equal false, @document.ispublic
  end

  test "should handle decimal precision for progress" do
    @document.save!
    @document.progress = 0.12345678
    @document.save!
    @document.reload
    # Test that decimal precision is maintained
    assert_in_delta 0.12345678, @document.progress, 0.00000001
  end
end
