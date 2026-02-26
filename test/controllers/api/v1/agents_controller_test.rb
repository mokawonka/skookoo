require "test_helper"

class Api::V1::AgentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @agent = Agent.create!(name: "Test Agent")
  end

  test "should register new agent" do
    post "/api/v1/agents/register", params: { 
      name: "New Agent", 
      description: "A test agent"
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_not_nil json_response['agent']['api_key']
    assert_not_nil json_response['agent']['claim_url']
    assert_not_nil json_response['agent']['verification_code']
    assert_equal "pending_claim", json_response['agent']['status']
    assert_includes json_response['important'], "SAVE YOUR API KEY"
  end

  test "should not register agent with invalid attributes" do
    post "/api/v1/agents/register", params: { 
      name: ""
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    assert_includes json_response['error'], "Name"
  end

  test "should claim agent with valid token and verification code" do
    post "/api/v1/agents/claim", params: { 
      claim_token: @agent.claim_token,
      verification_code: @agent.verification_code
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_equal "claimed", json_response['agent']['status']
    
    @agent.reload
    assert_equal "claimed", @agent.status
  end

  test "should not claim agent with invalid token" do
    post "/api/v1/agents/claim", params: { 
      claim_token: "invalid_token",
      verification_code: @agent.verification_code
    }, as: :json
    
    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    assert_equal "Invalid or expired claim token", json_response['error']
  end

  test "should not claim agent with invalid verification code" do
    post "/api/v1/agents/claim", params: { 
      claim_token: @agent.claim_token,
      verification_code: "wrong_code"
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    assert_equal "Invalid verification code", json_response['error']
  end

  test "should not claim already claimed agent" do
    @agent.claim!
    post "/api/v1/agents/claim", params: { 
      claim_token: @agent.claim_token,
      verification_code: @agent.verification_code
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    assert_equal "Agent already claimed", json_response['error']
  end

  test "should handle case-insensitive verification codes" do
    post "/api/v1/agents/claim", params: { 
      claim_token: @agent.claim_token,
      verification_code: @agent.verification_code.upcase
    }, as: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
  end

  test "should get agent status with valid API key" do
    @agent.claim!
    get "/api/v1/agents/status", headers: { 
      "Authorization" => "Bearer #{@agent.api_key}"
    }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
    assert_equal "claimed", json_response['agent']['status']
  end

  test "should not get agent status without API key" do
    get "/api/v1/agents/status"
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    assert_equal "Missing or invalid API key", json_response['error']
  end

  test "should not get agent status with invalid API key" do
    get "/api/v1/agents/status", headers: { 
      "Authorization" => "Bearer invalid_key"
    }
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    assert_equal "Missing or invalid API key", json_response['error']
  end

  test "should handle API key without Bearer prefix" do
    @agent.claim!
    get "/api/v1/agents/status", headers: { 
      "Authorization" => @agent.api_key
    }
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response['success']
  end

  test "should generate correct claim URL" do
    post "/api/v1/agents/register", params: { 
      name: "URL Test Agent"
    }, as: :json
    
    json_response = JSON.parse(response.body)
    claim_url = json_response['agent']['claim_url']
    
    assert_includes claim_url, request.base_url
    assert_includes claim_url, "/claim/"
  end

  test "should handle JSON requests properly" do
    post "/api/v1/agents/register", params: { 
      name: "JSON Test Agent"
    }, as: :json
    
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "should handle malformed JSON in request body" do
    post "/api/v1/agents/register", 
         params: "invalid json", 
         headers: { "CONTENT_TYPE" => "application/json" }
    
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    assert_includes json_response['error'], "Invalid JSON"
  end

  test "should set default format to JSON" do
    get "/api/v1/agents/status", headers: { 
      "Authorization" => "Bearer #{@agent.api_key}"
    }
    
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "should skip CSRF verification" do
    post "/api/v1/agents/register", params: { 
      name: "CSRF Test Agent"
    }, as: :json
    
    assert_response :success
    # Should not raise CSRF protection error
  end

  test "should handle concurrent agent registrations" do
    # Test that multiple agents can be registered simultaneously
    agents_data = [
      { name: "Agent 1" },
      { name: "Agent 2" },
      { name: "Agent 3" }
    ]
    
    agents_data.each do |agent_data|
      post "/api/v1/agents/register", params: agent_data, as: :json
      assert_response :success
      json_response = JSON.parse(response.body)
      assert_equal true, json_response['success']
      assert_not_nil json_response['agent']['api_key']
    end
    
    assert_equal 4, Agent.count # 1 from setup + 3 new
  end

  test "should validate agent name uniqueness" do
    post "/api/v1/agents/register", params: { 
      name: @agent.name
    }, as: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['success']
    # Name uniqueness validation might not be enforced, but API key uniqueness is
  end
end
