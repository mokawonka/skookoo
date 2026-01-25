class DocumentsController < ApplicationController
  protect_from_forgery except: :progress
  before_action :authorize_user!


  def index
    myuserid = session[:user_id]

    #retrieving all documents owned by current user
    @documents = Document.where(:userid => myuserid).order(
      Arel.sql("COALESCE(last_accessed_at, updated_at) DESC NULLS LAST")
    )


    @pagy, @records = pagy(@documents, items: 7)
  end



  def new
      @document = Document.new
  end

  def create

  end


  def show
    
    @document = Document.find(params[:id])
    @document.update_column(:last_accessed_at, Time.current)


    @highlights = Highlight.where(:docid => @document.id)
    @vocabs = Expression.where(:docid => @document.id)
    @ideas = Idea.where(:docid => @document.id)

  end


  def edit
    @document = Document.find(params[:id])
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
      params.require(:document).permit(:userid, :epubid, :title, :authors, :ispublic, :progress, :locations)
  end

end
