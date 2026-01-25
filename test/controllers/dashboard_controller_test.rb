require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get mydocuments" do
    get dashboard_mydocuments_url
    assert_response :success
  end
end
