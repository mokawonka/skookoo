# frozen_string_literal: true

module Api
  module V1
    class AgentsController < Api::BaseController
      before_action :authenticate_agent!, only: [:status]

      # POST /api/v1/agents/register
      def register
        agent = Agent.new(agent_register_params)
        if agent.save
          claim_url = claim_url_for(agent.claim_token)
          render_success(
            agent: {
              api_key: agent.api_key,
              claim_url: claim_url,
              verification_code: agent.verification_code,
              status: agent.status
            },
            important: "SAVE YOUR API KEY! You will need it for all authenticated requests."
          )
        else
          render_error(agent.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      # POST /api/v1/agents/claim
      def claim
        agent = Agent.find_by(claim_token: params[:claim_token])
        return render_error("Invalid or expired claim token", status: :not_found) unless agent
        return render_error("Agent already claimed", status: :unprocessable_entity) if agent.claimed?

        if agent.verification_code.to_s.downcase != params[:verification_code].to_s.strip.downcase
          return render_error("Invalid verification code", hint: "Check the code you received at registration")
        end

        agent.claim!
        render_success(agent: { status: agent.status })
      end

      # GET /api/v1/agents/status
      def status
        render_success(agent: { status: @current_agent.status })
      end

      private

      def agent_register_params
        params.permit(:name, :description)
      end

      def authenticate_agent!
        @current_agent = Agent.authenticate_by_api_key(auth_header)
        return render_error("Missing or invalid API key", hint: "Use Authorization: Bearer YOUR_API_KEY", status: :unauthorized) unless @current_agent
      end

      def auth_header
        request.authorization
      end

      def claim_url_for(claim_token)
        "#{request.base_url}/claim/#{claim_token}"
      end
    end
  end
end
