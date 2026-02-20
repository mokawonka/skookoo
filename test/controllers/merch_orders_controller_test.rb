require "test_helper"

class MerchOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get merch_orders_new_url
    assert_response :success
  end

  test "should get create" do
    get merch_orders_create_url
    assert_response :success
  end
end
