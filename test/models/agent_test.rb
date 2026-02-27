require "test_helper"

class AgentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
    @agent = Agent.new(
      name: "Test Agent",
      api_key: "skookoo_test_key_123",
      claim_token: "test_claim_token_456",
      verification_code: "skookoo-123456",
      status: "pending_claim"
    )
  end

  test "should be valid" do
    assert @agent.valid?
  end

  test "name should be present" do
    @agent.name = ""
    assert_not @agent.valid?
  end

  test "api_key should be present" do
    @agent.save!  # Save to generate the api_key
    original_api_key = @agent.api_key
    @agent.api_key = ""
    assert_not @agent.valid?
    
    # Test that it's valid with the generated key
    @agent.api_key = original_api_key
    assert @agent.valid?
  end

  test "api_key should be unique" do
    @agent.save
    duplicate_agent = @agent.dup
    duplicate_agent.api_key = @agent.api_key
    assert_not duplicate_agent.valid?
  end

  test "claim_token should be present" do
    @agent.save!  # Save to generate the claim_token
    original_claim_token = @agent.claim_token
    @agent.claim_token = ""
    assert_not @agent.valid?
    
    # Test that it's valid with the generated token
    @agent.claim_token = original_claim_token
    assert @agent.valid?
  end

  test "claim_token should be unique" do
    @agent.save
    duplicate_agent = @agent.dup
    duplicate_agent.claim_token = @agent.claim_token
    assert_not duplicate_agent.valid?
  end

  test "verification_code should be present" do
    @agent.save!  # Save to generate the verification_code
    original_verification_code = @agent.verification_code
    @agent.verification_code = ""
    assert_not @agent.valid?
    
    # Test that it's valid with the generated code
    @agent.verification_code = original_verification_code
    assert @agent.valid?
  end

  test "status should be present" do
    @agent.save!  # Save to set default status
    original_status = @agent.status
    @agent.status = ""
    assert_not @agent.valid?
    
    # Test that it's valid with the default status
    @agent.status = original_status
    assert @agent.valid?
  end

  test "status should be included in valid statuses" do
    valid_statuses = [Agent::STATUS_PENDING_CLAIM, Agent::STATUS_CLAIMED]
    valid_statuses.each do |status|
      @agent.status = status
      if status == Agent::STATUS_CLAIMED
        @agent.userid = @user&.id  # Set userid when claimed
      else
        @agent.userid = nil  # Clear userid when pending
      end
      assert @agent.valid?, "#{status} should be valid"
    end
    @agent.status = "invalid_status"
    assert_not @agent.valid?
  end

  test "userid should be present when claimed" do
    @agent.save!  # Save first to set all generated fields
    @agent.status = Agent::STATUS_CLAIMED
    @agent.userid = nil
    assert_not @agent.valid?

    user = User.create!(username: "userid_test_user", email: "userid_test@example.com", password: "password")
    @agent.userid = user.id
    assert @agent.valid?
  end

  test "userid should not be required when pending claim" do
    @agent.status = Agent::STATUS_PENDING_CLAIM
    @agent.userid = nil
    assert @agent.valid?
  end

  test "before_validation generates credentials on create" do
    agent = Agent.new(name: "New Agent")
    assert_nil agent.api_key
    assert_nil agent.claim_token
    assert_nil agent.verification_code
    assert_nil agent.status

    agent.save!
    assert_not_nil agent.api_key
    assert_not_nil agent.claim_token
    assert_not_nil agent.verification_code
    assert_equal Agent::STATUS_PENDING_CLAIM, agent.status
  end

  test "api_key should have correct prefix" do
    @agent.save!
    assert @agent.api_key.start_with?(Agent::API_KEY_PREFIX)
  end

  test "verification_code should have correct prefix" do
    @agent.save!
    assert @agent.verification_code.start_with?(Agent::VERIFICATION_PREFIX)
  end

  test "claimed? should return correct status" do
    @agent.status = Agent::STATUS_PENDING_CLAIM
    assert_not @agent.claimed?

    @agent.status = Agent::STATUS_CLAIMED
    assert @agent.claimed?
  end

  test "pending_claim? should return correct status" do
    @agent.status = Agent::STATUS_PENDING_CLAIM
    assert @agent.pending_claim?

    @agent.status = Agent::STATUS_CLAIMED
    assert_not @agent.pending_claim?
  end

  test "claim! should update status and userid" do
    @agent.save!  # Save first to set all generated fields
    claiming_user = User.create!(username: "claiming_user", email: "claim@example.com", password: "password")
    
    @agent.claim!(claiming_user)
    @agent.reload
    
    assert_equal Agent::STATUS_CLAIMED, @agent.status
    assert_equal claiming_user.id, @agent.userid
  end

  test "claim! without user should raise validation error" do
    @agent.save!
    
    assert_raises(ActiveRecord::RecordInvalid) do
      @agent.claim!
    end
  end

  test "authenticate_by_api_key should find agent by key" do
    @agent.save!
    
    found_agent = Agent.authenticate_by_api_key(@agent.api_key)
    assert_equal @agent, found_agent
  end

  test "authenticate_by_api_key should handle Bearer prefix" do
    @agent.save!
    
    found_agent = Agent.authenticate_by_api_key("Bearer #{@agent.api_key}")
    assert_equal @agent, found_agent
  end

  test "authenticate_by_api_key should return nil for blank key" do
    assert_nil Agent.authenticate_by_api_key("")
    assert_nil Agent.authenticate_by_api_key(nil)
  end

  test "authenticate_by_api_key should return nil for invalid key" do
    assert_nil Agent.authenticate_by_api_key("invalid_key")
  end

  test "scope claimed should return only claimed agents" do
    claimed_agent = Agent.create!(name: "Claimed Agent")
    pending_agent = Agent.create!(name: "Pending Agent")
    
    user = User.create!(username: "different_user", email: "different@example.com", password: "password")
    claimed_agent.claim!(user)
    
    claimed_agents = Agent.claimed
    assert_includes claimed_agents, claimed_agent
    assert_not_includes claimed_agents, pending_agent
  end

  test "scope pending_claim should return only pending agents" do
    claimed_agent = Agent.create!(name: "Claimed Agent")
    pending_agent = Agent.create!(name: "Pending Agent")
    
    user = User.create!(username: "pending_test_user", email: "pending_test@example.com", password: "password")
    claimed_agent.claim!(user)
    
    pending_agents = Agent.pending_claim
    assert_includes pending_agents, pending_agent
    assert_not_includes pending_agents, claimed_agent
  end

  test "associations should work correctly" do
    @agent.save!
    user = User.create!(username: "assoc_test_user", email: "assoc_test@example.com", password: "password")
    
    @agent.claim!(user)
    @agent.reload
    
    assert_equal user, @agent.user
  end

  test "generate_api_key should create unique keys" do
    keys = []
    10.times do
      agent = Agent.create!(name: "Agent #{keys.length}")
      keys << agent.api_key
    end
    
    assert_equal keys.length, keys.uniq.length
  end
end
