require "application_system_test_case"

class AgentManagementTest < ApplicationSystemTestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password")
  end

  test "agent registration and claiming workflow" do
    visit "/claim/new" # Assuming there's a claim registration page
    
    # Fill agent registration form
    fill_in "agent_name", with: "Test System Agent"
    fill_in "agent_description", with: "An agent for system testing"
    
    click_on "Register Agent"
    
    # Should show registration success with API key
    assert_text "Agent registered successfully"
    assert_text "SAVE YOUR API KEY"
    
    # Copy API key functionality (if implemented)
    find("#copy-api-key").click
    # Should show "Copied!" message
    
    # Store the displayed API key and claim token for claiming
    api_key = find("#api-key-display").text
    claim_token = find("#claim-token-display").text
    verification_code = find("#verification-code-display").text
    
    # Navigate to claim page
    visit "/claim/#{claim_token}"
    
    # Fill claim form
    fill_in "verification_code", with: verification_code
    click_on "Claim Agent"
    
    # Should show successful claim
    assert_text "Agent claimed successfully"
    assert_text "Status: claimed"
    
    # Test agent status page with API key
    visit "/agent/status"
    fill_in "api_key", with: api_key
    click_on "Check Status"
    
    # Should show agent status
    assert_text "Agent Status"
    assert_text "claimed"
  end

  test "agent API key validation" do
    visit "/agent/status"
    
    # Test with invalid API key
    fill_in "api_key", with: "invalid_key"
    click_on "Check Status"
    
    # Should show error
    assert_text "Invalid API key"
    assert_text "Missing or invalid API key"
    
    # Test with empty API key
    fill_in "api_key", with: ""
    click_on "Check Status"
    
    # Should show error
    assert_text "API key required"
  end

  test "agent management dashboard" do
    # Create and claim an agent first
    agent = Agent.create!(name: "Dashboard Test Agent")
    agent.claim!
    
    log_in_as(@user)
    visit "/dashboard/agents"
    
    # Should show list of user's agents
    assert_text "Dashboard Test Agent"
    assert_text "claimed"
    
    # Test agent actions
    within ".agent-#{agent.id}" do
      click_on "View Details"
    end
    
    # Should show agent details
    assert_text agent.name
    assert_text agent.api_key
    
    # Test regenerate API key (if implemented)
    click_on "Regenerate API Key"
    accept_confirm "Are you sure? This will invalidate the old key."
    
    # Should show new API key
    assert_text "New API Key Generated"
    assert_not_equal agent.api_key, find("#new-api-key").text
  end

  test "agent usage statistics" do
    # Create agent with usage data
    agent = Agent.create!(name: "Stats Test Agent")
    agent.claim!
    
    log_in_as(@user)
    visit "/dashboard/agents/#{agent.id}/stats"
    
    # Should show usage statistics
    assert_text "Usage Statistics"
    assert_text "API Calls"
    assert_text "Last Used"
    
    # Test date range filtering
    select "Last 7 days", from: "date_range"
    click_on "Update"
    
    # Should update statistics
    assert_text "Last 7 days"
  end

  test "agent documentation and examples" do
    visit "/docs/agents"
    
    # Should show API documentation
    assert_text "Agent API Documentation"
    assert_text "Authentication"
    assert_text "Endpoints"
    
    # Test code examples
    find(".example-curl").click
    assert_text "curl -X POST"
    
    find(".example-javascript").click
    assert_text "fetch("
    
    find(".example-python").click
    assert_text "requests.post"
    
    # Test interactive API tester
    fill_in "test_api_key", with: "test_key"
    select "status", from: "test_endpoint"
    click_on "Test Request"
    
    # Should show test results
    assert_text "Response"
  end

  test "agent security features" do
    log_in_as(@user)
    agent = Agent.create!(name: "Security Test Agent")
    agent.claim!
    
    visit "/dashboard/agents/#{agent.id}/security"
    
    # Should show security settings
    assert_text "Security Settings"
    assert_text "API Key Rotation"
    assert_text "Access Logs"
    
    # Test API key rotation
    click_on "Rotate API Key"
    accept_confirm "This will invalidate the current API key."
    
    # Should show new key
    assert_text "New API key generated"
    
    # Test access logs
    click_on "View Access Logs"
    assert_text "Recent API Access"
    assert_text "IP Address"
    assert_text "Timestamp"
  end

  test "agent rate limiting display" do
    log_in_as(@user)
    visit "/dashboard/agents/rate-limits"
    
    # Should show rate limiting information
    assert_text "Rate Limits"
    assert_text "Requests per minute"
    assert_text "Requests per hour"
    assert_text "Current usage"
    
    # Should show visual indicators
    assert_selector ".rate-limit-progress"
    assert_selector ".usage-indicator"
  end

  test "agent error handling" do
    visit "/claim/nonexistent-token"
    
    # Should show 404 error
    assert_text "Claim token not found"
    assert_text "Invalid or expired claim token"
    
    # Test invalid verification code
    agent = Agent.create!(name: "Error Test Agent")
    visit "/claim/#{agent.claim_token}"
    
    fill_in "verification_code", with: "wrong_code"
    click_on "Claim Agent"
    
    # Should show validation error
    assert_text "Invalid verification code"
    assert_text "Check the code you received"
  end

  test "real-time agent status updates" do
    agent = Agent.create!(name: "Real-time Test Agent")
    agent.claim!
    
    visit "/dashboard/agents"
    
    # Test WebSocket or polling for real-time updates
    # This would depend on the implementation
    
    # Simulate agent status change
    agent.update!(status: "pending_claim")
    
    # Should update status in real-time
    # This would require JavaScript testing
    assert_text "pending_claim"
  end

  test "agent configuration management" do
    log_in_as(@user)
    agent = Agent.create!(name: "Config Test Agent")
    agent.claim!
    
    visit "/dashboard/agents/#{agent.id}/config"
    
    # Should show configuration options
    assert_text "Agent Configuration"
    assert_text "Webhook URL"
    assert_text "Notification Settings"
    
    # Update configuration
    fill_in "webhook_url", with: "https://example.com/webhook"
    check "enable_notifications"
    click_on "Save Configuration"
    
    # Should show success message
    assert_text "Configuration saved"
    
    # Test configuration validation
    fill_in "webhook_url", with: "invalid-url"
    click_on "Save Configuration"
    
    # Should show validation error
    assert_text "Invalid URL format"
  end

  private

  def log_in_as(user)
    visit login_path
    fill_in "session_username", with: user.username
    fill_in "session_password", with: "password"
    click_on "Log In"
  end
end
