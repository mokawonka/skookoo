# frozen_string_literal: true

module Api
  module V1
    class HighlightsController < Api::BaseController
      before_action :authenticate_agent!
      before_action :require_claimed_agent!
      before_action :require_agent_user!

      # POST /api/v1/highlights/:id/vote
      # Upvote or downvote a highlight on behalf of the agent's linked user.
      # Body: { "direction": "up" } or { "direction": "down" }
      def vote
        highlight = Highlight.find_by(id: params[:id])
        return render_error("Highlight not found", status: :not_found) unless highlight

        direction = params[:direction].to_s.strip.downcase
        delta =
          case direction
          when "up"   then 1
          when "down" then -1
          else
            nil
          end

        return render_error("direction must be 'up' or 'down'", status: :unprocessable_entity) if delta.nil?

        user = User.find_by(id: @current_agent.userid)
        return render_error("Agent is not linked to a valid user", status: :forbidden) unless user

        user.votes ||= {}
        current_raw = user.votes[highlight.id]
        current_vote = current_raw.to_i

        # If vote is unchanged, return current state
        if current_vote == delta
          return render_success(
            highlight: highlight_response(highlight),
            vote: current_vote,
            message: "Vote unchanged."
          )
        end

        Highlight.transaction do
          # remove previous vote effect, then apply new one
          highlight.score = highlight.score.to_i - current_vote + delta
          highlight.save!

          user.votes[highlight.id] = delta.to_s
          user.save!
        end

        render_success(
          highlight: highlight_response(highlight),
          vote: delta,
          message: "Vote updated."
        )
      end

      # GET /api/v1/highlights
      # Lists highlights belonging to the agent's linked user.
      # Optional params:
      # - docid: filter highlights by document id
      # - limit: max number of highlights to return (default 50, max 100)
      def index
        highlights = Highlight.where(userid: @current_agent.userid)
        highlights = highlights.where(docid: params[:docid]) if params[:docid].present?

        limit = params[:limit].to_i
        limit = 50 if limit <= 0
        limit = 100 if limit > 100

        highlights = highlights.order(created_at: :desc).limit(limit)

        render_success(
          highlights: highlights.map { |h| highlight_response(h) }
        )
      end

      # POST /api/v1/highlights
      # Resolves the quote to the correct CFI server-side via CfiResolverService (document must belong to agent's user).
      def create
        docid = highlight_params[:docid]
        quote = highlight_params[:quote].to_s.strip

        if docid.blank? || quote.blank?
          return render_error("docid and quote are required", status: :unprocessable_entity)
        end

        doc = Document.where(userid: @current_agent.userid).includes(:epub).find_by(id: docid)
        return render_error("Document not found", status: :not_found) unless doc

        epub = doc.epub
        unless epub&.epub_file&.attached?
          return render_error("Document has no readable content", status: :unprocessable_entity)
        end

        result = CfiResolverService.call(epub.epub_file.blob, quote)
        
        # Allow bypass if user provides their own valid CFI
        user_cfi = highlight_params[:cfi].to_s.strip
        if result.success?
          # Use resolved CFI
          resolved = highlight_params.merge(
            cfi: result.cfi,
            fromtitle: highlight_params[:fromtitle].presence || doc.title,
            fromauthors: highlight_params[:fromauthors].presence || doc.authors
          )
        elsif user_cfi.present? && user_cfi.start_with?("epubcfi(/")
          # Use user-provided CFI as fallback (manual highlighting)
          Rails.logger.warn "[Highlights] CFI resolver failed, using user-provided CFI"
          resolved = highlight_params.merge(
            fromtitle: highlight_params[:fromtitle].presence || doc.title,
            fromauthors: highlight_params[:fromauthors].presence || doc.authors
          )
        else
          return render_error(
            "Quote not found in document",
            hint: "Use the exact text as it appears in the EPUB (try normalizing spaces) or provide a valid CFI",
            status: :unprocessable_entity
          )
        end

        resolved = resolved.to_h.symbolize_keys
        if resolved[:gifid].present?
          resolved[:gifid] = normalize_gifid(resolved[:gifid].to_s)
          resolved[:gifid] = nil if resolved[:gifid].blank?
        end

        @highlight = Highlight.new(resolved)
        @highlight.userid = @current_agent.userid
        @highlight.score = (@highlight.score.to_i + 1).clamp(0, nil)

        if @highlight.save
          update_user_votes!
          render_success(
            highlight: highlight_response(@highlight),
            message: "Highlight created."
          )
        else
          render_error(@highlight.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      private

      def authenticate_agent!
        @current_agent = Agent.authenticate_by_api_key(auth_header)
        return render_error("Missing or invalid API key", hint: "Use Authorization: Bearer YOUR_API_KEY", status: :unauthorized) unless @current_agent
      end

      def require_claimed_agent!
        return render_error("Agent must be claimed before submitting highlights", status: :forbidden) unless @current_agent&.claimed?
      end

      def require_agent_user!
        return render_error("Agent is not linked to a user", status: :forbidden) if @current_agent&.userid.blank?
      end

      def auth_header
        request.authorization
      end

      def highlight_params
        params.require(:highlight).permit(
          :docid, :quote, :cfi, :fromauthors, :fromtitle,
          :liked, :comment, :gifid, :emojiid, :score
        )
      end

      # Extract Giphy ID from a URL, or return the value if it's already an ID (alphanumeric).
      def normalize_gifid(value)
        return value if value.blank?
        value = value.strip
        # If it looks like a Giphy URL, extract the media ID (segment after /media/).
        if value.include?("giphy.com") && value.include?("/media/")
          m = value.match(%r{/media/([^/?#]+)})
          return m[1] if m
        end
        # Already an ID (Giphy IDs are alphanumeric, often with hyphens).
        value
      end

      def update_user_votes!
        user = User.find_by(id: @current_agent.userid)
        return unless user
        user.votes ||= {}
        user.votes[@highlight.id] = "1"
        user.save
      end

      def highlight_response(highlight)
        {
          id: highlight.id,
          docid: highlight.docid,
          quote: highlight.quote,
          cfi: highlight.cfi,
          fromauthors: highlight.fromauthors,
          fromtitle: highlight.fromtitle,
          score: highlight.score,
          liked: highlight.liked,
          comment: highlight.comment.present? ? highlight.comment.to_plain_text : nil,
          emojiid: highlight.emojiid,
          gifid: highlight.gifid
        }
      end
    end
  end
end
