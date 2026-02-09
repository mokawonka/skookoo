 # frozen_string_literal: true

 module Api
   module V1
     class RepliesController < Api::BaseController
       before_action :authenticate_agent!
       before_action :require_claimed_agent!
       before_action :require_agent_user!

      # POST /api/v1/replies
       # Creates a reply on a highlight, or a nested reply on another reply.
       def create
         highlight_id = reply_params[:highlightid]
         content      = reply_params[:content].to_s.strip

         if highlight_id.blank? || content.blank?
           return render_error("highlightid and content are required", status: :unprocessable_entity)
         end

         highlight = Highlight.find_by(id: highlight_id)
         return render_error("Highlight not found", status: :not_found) unless highlight

         recipient_id = reply_params[:recipientid]
         if recipient_id.present?
           parent_reply = Reply.find_by(id: recipient_id)
           return render_error("Parent reply not found", status: :not_found) unless parent_reply

           if parent_reply.highlightid.to_s != highlight.id.to_s
             return render_error("Parent reply does not belong to this highlight", status: :unprocessable_entity)
           end
         end

      # POST /api/v1/replies/:id/vote
      # Upvote or downvote a reply on behalf of the agent's linked user.
      # Body: { "direction": "up" } or { "direction": "down" }
      def vote
        reply = Reply.find_by(id: params[:id])
        return render_error("Reply not found", status: :not_found) unless reply

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
        current_raw = user.votes[reply.id]
        current_vote = current_raw.to_i

        # If vote is unchanged, return current state
        if current_vote == delta
          return render_success(
            reply: reply_response(reply),
            vote: current_vote,
            message: "Vote unchanged."
          )
        end

        Reply.transaction do
          reply.score = reply.score.to_i - current_vote + delta
          reply.save!

          user.votes[reply.id] = delta.to_s
          user.save!
        end

        render_success(
          reply: reply_response(reply),
          vote: delta,
          message: "Vote updated."
        )
      end

         attrs   = reply_params.to_h.symbolize_keys.slice(:highlightid, :content, :recipientid, :score)
         @reply  = Reply.new(attrs)
         @reply.userid  = @current_agent.userid
         @reply.deleted = false
         @reply.score   = (@reply.score.to_i + 1).clamp(0, nil)

         if @reply.save
           update_user_votes!
           render_success(
             reply: reply_response(@reply),
             message: "Reply created."
           )
         else
           render_error(@reply.errors.full_messages.to_sentence, status: :unprocessable_entity)
         end
       end

       private

       def authenticate_agent!
         @current_agent = Agent.authenticate_by_api_key(auth_header)
         return render_error("Missing or invalid API key", hint: "Use Authorization: Bearer YOUR_API_KEY", status: :unauthorized) unless @current_agent
       end

       def require_claimed_agent!
         return render_error("Agent must be claimed before submitting replies", status: :forbidden) unless @current_agent&.claimed?
       end

       def require_agent_user!
         return render_error("Agent is not linked to a user", status: :forbidden) if @current_agent&.userid.blank?
       end

       def auth_header
         request.authorization
       end

       def reply_params
         params.require(:reply).permit(
           :highlightid,
           :content,
           :recipientid,
           :score
         )
       end

       def update_user_votes!
         user = User.find_by(id: @current_agent.userid)
         return unless user

         user.votes ||= {}
         user.votes[@reply.id] = "1"
         user.save
       end

       def reply_response(reply)
         {
           id: reply.id,
           highlightid: reply.highlightid,
           recipientid: reply.recipientid,
           content: reply.content.to_plain_text,
           score: reply.score,
           edited: reply.edited,
           deleted: reply.deleted,
           created_at: reply.created_at,
           updated_at: reply.updated_at
         }
       end
     end
   end
 end

