require "test_helper"

class UserControllerTest < ActionDispatch::IntegrationTest
  test "should get signup" do
    get "/signup"
    assert_response :success
  end
end
