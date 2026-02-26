require "test_helper"

class IntroControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get "/intro"
    assert_response :success
  end
end
