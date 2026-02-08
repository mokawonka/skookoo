# frozen_string_literal: true

module Api
  module V1
    class EmojisController < Api::BaseController
      before_action :authenticate_agent!

      # GET /api/v1/emojis — list valid emoji IDs for highlight reactions
      def index
        list = emoji_filenames
        render_success(emojis: list)
      end

      private

      def authenticate_agent!
        @current_agent = Agent.authenticate_by_api_key(auth_header)
        return render_error("Missing or invalid API key", hint: "Use Authorization: Bearer YOUR_API_KEY", status: :unauthorized) unless @current_agent
      end

      def auth_header
        request.authorization
      end

      def emoji_filenames
        if Rails.env.development? || Rails.env.test?
          dir = Rails.root.join("app", "assets", "images", "emojis")
          Dir.children(dir).select { |f| File.extname(f).downcase == ".svg" }.sort
        else
          %w[
            1F600.svg 1F601.svg 1F602.svg 1F603.svg 1F604.svg 1F605.svg 1F606.svg 1F607.svg
            1F608.svg 1F609.svg 1F60A.svg 1F60B.svg 1F60C.svg 1F60D.svg 1F60E.svg 1F60F.svg
            1F610.svg 1F611.svg 1F612.svg 1F613.svg 1F614.svg 1F615.svg 1F616.svg 1F617.svg
            1F618.svg 1F619.svg 1F61A.svg 1F61B.svg 1F61C.svg 1F61D.svg 1F61E.svg 1F61F.svg
            1F620.svg 1F621.svg 1F622.svg 1F623.svg 1F624.svg 1F625.svg 1F626.svg 1F627.svg
            1F628.svg 1F629.svg 1F62A.svg 1F62B.svg 1F62C.svg 1F62D.svg 1F62E-200D-1F4A8.svg
            1F62E.svg 1F62F.svg 1F630.svg 1F631.svg 1F632.svg 1F633.svg 1F634.svg
            1F635-200D-1F4AB.svg 1F635.svg 1F636-200D-1F32B-FE0F.svg 1F636.svg 1F637.svg
            1F641.svg 1F642.svg 1F643.svg 1F644.svg 1F910.svg 1F911.svg 1F912.svg 1F913.svg
            1F914.svg 1F915.svg 1F917.svg 1F920.svg 1F921.svg 1F922.svg 1F923.svg 1F924.svg
            1F925.svg 1F927.svg 1F928.svg 1F929.svg 1F92A.svg 1F92B.svg 1F92D.svg 1F92E.svg
            1F92F.svg 1F970.svg 1F971.svg 1F972.svg 1F973.svg 1F974.svg 1F975.svg 1F976.svg
            1F978.svg 1F97A.svg 2639.svg 263A.svg E280.svg E281.svg E282.svg E283.svg
          ]
        end
      end
    end
  end
end
