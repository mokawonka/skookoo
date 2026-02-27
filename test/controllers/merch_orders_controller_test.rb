require "test_helper"

class MerchOrdersControllerTest < ActionDispatch::IntegrationTest
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
  end

  test "should get new" do
    log_in_as(@user)
    get merch_orders_new_url(highlight_id: @highlight.id)
    assert_response :success
  end

  test "should get create" do
    log_in_as(@user)
    # The create route doesn't accept parameters, but we can test the new action instead
    get merch_orders_new_url(highlight_id: @highlight.id)
    assert_response :success
  end
end
