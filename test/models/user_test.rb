require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      username: "testuser",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "username should be present" do
    @user.username = ""
    assert_not @user.valid?
  end

  test "username should be unique" do
    @user.save
    duplicate_user = @user.dup
    assert_not duplicate_user.valid?
  end

  test "username should have minimum length of 2" do
    @user.username = "a"
    assert_not @user.valid?
    @user.username = "ab"
    assert @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "email should be unique" do
    @user.save
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    assert_not duplicate_user.valid?
  end

  test "email should be valid format" do
    valid_emails = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                     first.last@foo.jp alice+bob@baz.cn]
    valid_emails.each do |email|
      @user.email = email
      assert @user.valid?, "#{email} should be valid"
    end

    invalid_emails = %w[user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?, "#{email} should be invalid"
    end
  end

  test "password should be present" do
    @user.password = @user.password_confirmation = ""
    assert_not @user.valid?
  end

  test "password should have minimum length of 3" do
    @user.password = @user.password_confirmation = "a" * 2
    assert_not @user.valid?
    @user.password = @user.password_confirmation = "a" * 3
    assert @user.valid?
  end

  test "password confirmation should match" do
    @user.password_confirmation = "mismatch"
    assert_not @user.valid?
  end

  test "has_secure_password" do
    @user.save
    assert @user.authenticate("password123")
    assert_not @user.authenticate("incorrect")
  end

  test "default attributes should be set correctly" do
    user = User.new(
      username: "test",
      email: "test@example.com",
      password: "password"
    )
    assert_equal 1, user.mana
    assert_equal false, user.darkmode
    assert_equal true, user.allownotifications
    assert_equal true, user.emailnotifications
    assert_equal 'League Spartan Bold', user.font
  end

  test "serialized attributes should work correctly" do
    @user.save
    assert_equal Hash, @user.votes.class
    assert_equal Array, @user.following.class
    assert_equal Array, @user.followers.class
    assert_equal Array, @user.pending_follow_requests.class
  end

  test "getvote method should return correct values" do
    @user.votes = { "1" => "1", "2" => "-1", "3" => "" }
    @user.save!

    assert_equal 1, @user.getvote("1")
    assert_equal(-1, @user.getvote("2"))
    assert_nil @user.getvote("3") # Empty string returns nil
    assert_equal 0, @user.getvote("nonexistent")
  end

  test "plan method should return subscription plan or default" do
    user_without_subscription = User.new(username: "test", email: "test@example.com")
    assert_equal 'janitor', user_without_subscription.plan

    @user.save
    subscription = Subscription.create(user: @user, plan: 'pomologist', status: 'active')
    assert_equal 'pomologist', @user.plan
  end

  test "pomologist? should return correct status" do
    @user.save
    
    assert_not @user.pomologist?

    subscription = Subscription.create(user: @user, plan: 'pomologist', status: 'active')
    assert @user.pomologist?

    subscription.update(status: 'canceled')
    assert_not @user.pomologist?

    subscription.update(status: 'trialing')
    assert @user.pomologist?
  end

  test "private? should return private_profile value" do
    @user.private_profile = true
    assert @user.private?

    @user.private_profile = false
    assert_not @user.private?
  end

  test "approved_follower? should work correctly" do
    @user.save
    follower = User.create!(username: "follower", email: "follower@example.com", password: "password")
    
    assert_not @user.approved_follower?(nil)
    assert_not @user.approved_follower?(follower)

    @user.following = [follower.id]
    @user.save
    assert @user.approved_follower?(follower)
  end

  test "has_pending_follow_request_from? should work correctly" do
    @user.save
    requester = User.create!(username: "requester", email: "req@example.com", password: "password")
    
    assert_not @user.has_pending_follow_request_from?(nil)
    assert_not @user.has_pending_follow_request_from?(requester)

    @user.pending_follow_requests = [requester.id]
    @user.save
    assert @user.has_pending_follow_request_from?(requester)
  end

  test "associations should work correctly" do
    @user.save
    
    assert_respond_to @user, :notifications
    assert_respond_to @user, :agents
    assert_respond_to @user, :merch_orders
    assert_respond_to @user, :subscription
    assert_respond_to @user, :avatar_attachment
  end

  test "after_create callback creates default subscription" do
    user_count = User.count
    subscription_count = Subscription.count
    
    user = User.create!(
      username: "newuser",
      email: "new@example.com",
      password: "password"
    )
    
    assert_equal user_count + 1, User.count
    assert_equal subscription_count + 1, Subscription.count
    assert_not_nil user.subscription
    assert_equal 'janitor', user.subscription.plan
    assert_equal 'active', user.subscription.status
  end
end
