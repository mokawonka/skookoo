class HighlightsController < ApplicationController
  skip_before_action :require_user, only: [:show]
  skip_before_action :verify_authenticity_token
  before_action :authorize_user! , only: [:create, :destroy, :update_score]
  # before_action :check_timestamp , only: [:create, :destroy, :update_score]

  
  def new
    @highlight = Highlight.new
  end


  def create
    @highlight = Highlight.new(highlight_params)
    @highlight.userid = session[:user_id]
    @highlight.score += 1

    respond_to do |format|

      if @highlight.save
        format.js
        flash.now[:notice] = "Highlight added successfully"
        current_user.votes[@highlight.id] = "1"
        current_user.save
      else
        format.js
        flash.now[:notice] = ""
        @highlight.errors.full_messages.each do |message|
          flash.now[:notice] =  flash.now[:notice] + ' - ' + message
        end
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
      @highlight.score += value.to_i
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