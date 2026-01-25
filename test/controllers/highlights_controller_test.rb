require "test_helper"

class HighlightsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get highlights_new_url
    assert_response :success
  end
end
