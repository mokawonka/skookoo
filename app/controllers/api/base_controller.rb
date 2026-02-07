# frozen_string_literal: true

module Api
  class BaseController < ActionController::Base
    skip_before_action :verify_authenticity_token
    before_action :set_default_format_json

    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    private

    def set_default_format_json
      request.format = :json unless params[:format]
    end

    def render_success(data = {})
      render json: { success: true }.merge(data), status: :ok
    end

    def render_error(message, hint: nil, status: :unprocessable_entity)
      payload = { success: false, error: message }
      payload[:hint] = hint if hint.present?
      render json: payload, status: status
    end

    def render_unprocessable(exception)
      render_error(exception.record&.errors&.full_messages&.to_sentence || exception.message, status: :unprocessable_entity)
    end

    def render_not_found(_exception = nil)
      render_error("Resource not found", status: :not_found)
    end
  end
end
