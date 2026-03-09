class HighlightsController < ApplicationController
  skip_before_action :require_user, only: [:show]
  skip_before_action :verify_authenticity_token
  before_action :check_timestamp , only: [:create, :destroy, :update_score]
  skip_before_action :require_user, if: -> { params[:token].present? }

  
  def new
    @highlight = Highlight.new
  end


  
  def create
    token = params[:token].presence
    user = token.present? ? user_from_token(token) : current_user  
    
    if user.blank?
      respond_to do |format|
        format.json { render json: { error: "Authentication required" }, status: :unauthorized }
        format.js   { render js: "alert('Please reconnect or log in.');" }
        format.html { redirect_to login_path, alert: "Please log in" }
      end
      return
    end  
    @highlight = Highlight.new(highlight_params)
    @highlight.userid = user.id
    @highlight.score += 1  
    
    respond_to do |format|
      if @highlight.save
        user.votes ||= {}
        user.votes[@highlight.id] = "1"
        user.save  
        
        flash.now[:success] = "Highlight added successfully"

        if token.present?
          format.json { render json: { success: true, message: flash.now[:success] } }
        else
          format.js   # Renders create.js.erb
          format.html { redirect_to document_path(@highlight.docid), notice: flash.now[:success] }
        end
      else
        flash.now[:alert] = @highlight.errors.full_messages.join(", ")

        format.json { render json: { error: flash.now[:alert] }, status: :unprocessable_entity }
        format.js   { render js: "alert('Failed: #{j flash.now[:alert]}');" }
        format.html { redirect_back fallback_location: root_path, alert: flash.now[:alert] }
      end  
    end
  end




  def show

    @highlight = Highlight.find_by_id(params[:id])

    @document = Document.find_by_id(@highlight.docid)

    # getting only replies with no parents
    # we call the children recursively later on in the highlightreplies view
    @replies = Reply.where(:highlightid => @highlight.id).where(:deleted => false).where(:recipientid => nil)

    # for the user who wants to comment later on
    @reply = Reply.new


    ActiveStorage::Current.url_options = { host: request.host, protocol: request.protocol, port: request.port }
    set_meta_tags(
      title: @highlight.fromtitle,
      description: @highlight.quote.truncate(160),
      og: {
        title: @highlight.fromtitle,
        description: @highlight.quote.truncate(160),
        image: @highlight.og_image.url,  # URL to the generated image
        url: request.url
      },
      twitter: {
        card: 'summary_large_image',
        image: @highlight.og_image.url
      }
    )

  end



  def update_score

    @highlight = Highlight.find(params[:id])

    params[:highlight].each do |increment, value|
      @highlight.increment!(:score, value.to_i)
    end

    respond_to do |format|
  
      if @highlight.update(highlight_params)
          format.js
      end

    end

  end
  


  def destroy

    highlighttodelete = Highlight.find(params[:id])

    if current_user == User.find_by_id(highlighttodelete.userid)

          # soft-deleting all highlight replies
          Reply.where(highlightid: highlighttodelete.id).update_all(deleted: true)  

          highlighttodelete.destroy!

          # Decide redirection based on 'from' param
          if params[:from] == "document"
            # Redirect back to the same page → effectively refreshes it
            redirect_back(fallback_location: root_path)
          elsif params[:from] == "highlight"
            # Default: coming from highlights or anywhere else → go to profile
            redirect_to user_path(current_user.username)
          end
    end
  end


  private

  def highlight_params

      params.require(:highlight).permit(:userid, :docid, :quote, :cfi, :liked, :comment, :gifid, 
                                        :emojiid, :score, :fromauthors, :fromtitle)
  end

  
end