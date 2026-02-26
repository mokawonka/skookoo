require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get mydocuments" do
    get "/dashboard/mydocuments"
    assert_response :success
  end
end
