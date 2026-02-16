class DocumentsController < ApplicationController
  skip_before_action :require_user, only: [:show, :not_public]
  protect_from_forgery except: :progress
  before_action :authorize_user!, only: [:create, :index, :destroy, :edit,
                                         :update, :update_locations, :update_progress]


  def index
    myuserid = session[:user_id]

    #retrieving all documents owned by current user (eager load epubs to avoid N+1)
    @documents = Document.where(:userid => myuserid).includes(:epub).order(
      Arel.sql("COALESCE(last_accessed_at, updated_at) DESC NULLS LAST")
    )

    @pagy, @records = pagy(@documents, items: 7)
  end



  def new
      @document = Document.new
  end

  def create

  end

  def not_public

  end


  def show
    @document = Document.find(params[:id])
    @affiliated_epub = Epub.find(@document.epubid)
    @giphyApiKey = ""

    if logged_in? && current_user.id == @document.userid

      @giphyApiKey = "Vsa6RyTveLS9mFOQVsTPmE8vndGnKc6G"
      @document.update_column(:last_accessed_at, Time.current)
      @highlights = Highlight.where(:docid => @document.id)
      if params[:cfi].present?
        @target_highlight = @highlights.find_by(cfi: params[:cfi])
      end 
      @vocabs = Expression.where(:docid => @document.id)
      
    else
      if !@document.ispublic
        redirect_to document_not_public_path and return
      else
        @highlights = Highlight.where(:docid => @document.id)
        if params[:cfi].present?
          @target_highlight = @highlights.find_by(cfi: params[:cfi])
        end
      end
    end

  end


  def edit
    @document = Document.find(params[:id])
  end



  def update_settings
    @document = Document.find(params[:id])

    # Only the owner can update
    unless current_user && current_user.id == @document.userid
      head :forbidden
      return
    end

    # Update settings
    if @document.update(
        font_size: params[:font_size],
        line_height: params[:line_height],
        bg_color: params[:bg_color],
        text_color: params[:text_color]
      )
      render json: { status: "ok" }
    else
      render json: { status: "error", errors: @document.errors.full_messages }, status: 422
    end
  end



  def update
    @document = Document.find(params[:id])

    respond_to do |format|

      if @document.update(document_params)
          format.js
      end

    end

  end


  def update_locations
    @document = Document.find(params[:id])

    @document.opened = 1;

    respond_to do |format|
  
      if @document.update(document_params)
          format.js
      end

    end

  end

  def update_progress
    @document = Document.find(params[:id])

    respond_to do |format|
  
      if @document.update(document_params)
          format.js
      end

    end

  end


  def destroy
    Document.find(params[:id]).destroy!
    flash.now[:notice] = "Document deleted successfully"
    redirect_to documents_path
  end


  private

  def document_params
      # for whitelisting the parameters for documents to be set
      params.require(:document).permit(:userid, :epubid, :title, :authors, :ispublic, :progress,
                                       :font_size, :line_height, :bg_color, :text_color, :locations)
  end

end
