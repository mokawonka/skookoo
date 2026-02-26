require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @subscription = Subscription.new(user: @user)
  end

  test "should be valid" do
    assert @subscription.valid?
  end

  test "belongs to user should work" do
    @subscription.save!
    assert_equal @user, @subscription.user
  end

  test "default plan should be janitor" do
    @subscription.save!
    assert_equal "janitor", @subscription.plan
  end

  test "default status should be active" do
    @subscription.save!
    assert_equal "active", @subscription.status
  end

  test "plan should accept valid values" do
    valid_plans = %w[janitor pomologist]
    valid_plans.each do |plan|
      @subscription.plan = plan
      assert @subscription.valid?, "#{plan} should be valid"
    end
  end

  test "status should accept valid values" do
    valid_statuses = %w[active trialing past_due canceled]
    valid_statuses.each do |status|
      @subscription.status = status
      assert @subscription.valid?, "#{status} should be valid"
    end
  end

  test "active_or_trial? should return true for active status" do
    @subscription.status = "active"
    assert @subscription.active_or_trial?
  end

  test "active_or_trial? should return true for trialing status" do
    @subscription.status = "trialing"
    assert @subscription.active_or_trial?
  end

  test "active_or_trial? should return false for past_due status" do
    @subscription.status = "past_due"
    assert_not @subscription.active_or_trial?
  end

  test "active_or_trial? should return false for canceled status" do
    @subscription.status = "canceled"
    assert_not @subscription.active_or_trial?
  end

  test "plan should be updatable" do
    @subscription.save!
    @subscription.plan = "pomologist"
    @subscription.save!
    @subscription.reload
    assert_equal "pomologist", @subscription.plan
  end

  test "status should be updatable" do
    @subscription.save!
    @subscription.status = "canceled"
    @subscription.save!
    @subscription.reload
    assert_equal "canceled", @subscription.status
  end

  test "should handle enum methods for plan" do
    @subscription.save!
    
    @subscription.janitor!
    assert @subscription.janitor?
    assert_not @subscription.pomologist?
    
    @subscription.pomologist!
    assert @subscription.pomologist?
    assert_not @subscription.janitor?
  end

  test "should handle enum methods for status" do
    @subscription.save!
    
    @subscription.active!
    assert @subscription.active?
    assert_not @subscription.trialing?
    assert_not @subscription.past_due?
    assert_not @subscription.canceled?
    
    @subscription.trialing!
    assert @subscription.trialing?
    assert_not @subscription.active?
    
    @subscription.past_due!
    assert @subscription.past_due?
    assert_not @subscription.active?
    
    @subscription.canceled!
    assert @subscription.canceled?
    assert_not @subscription.active?
  end

  test "should require user association" do
    subscription = Subscription.new(user: nil)
    assert_not subscription.valid?
  end

  test "should create subscription with custom values" do
    subscription = Subscription.create!(
      user: @user,
      plan: "pomologist",
      status: "trialing"
    )
    
    assert_equal "pomologist", subscription.plan
    assert_equal "trialing", subscription.status
    assert subscription.trialing?
    assert subscription.pomologist?
  end
end
