class DocumentsController < ApplicationController
  skip_before_action :require_user, only: [:show, :not_public]
  protect_from_forgery except: :progress


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
      title        = params[:title]&.strip
      authors      = params[:authors]&.strip.presence || current_user.name
      content_html = params[:content]&.strip
      ispublic     = params[:ispublic] == "1"

      if title.blank? || content_html.blank?
        flash.now[:alert] = "Title and content are required"
        render :new and return
      end

      tmpfile = nil

      begin
        tmpfile = build_epub(title, authors, content_html)

        @epub = Epub.new(
          title:         title,
          authors:       authors,
          lang:          "en",
          public_domain: false,
          sha3:          SHA3::Digest.file(tmpfile.path).hexdigest
        )

        @epub.epub_file.attach(
          io:           File.open(tmpfile.path),
          filename:     "#{title.parameterize}.epub",
          content_type: "application/epub+zip"
        )

        unless @epub.save
          flash.now[:alert] = @epub.errors.full_messages.to_sentence
          render :new and return
        end

        @document = Document.new(
          userid:   session[:user_id],
          epubid:   @epub.id,
          title:    title,
          authors:  authors,
          ispublic: ispublic
        )

        if @document.save
          redirect_to document_path(@document), notice: "Published successfully!"
        else
          @epub.destroy
          flash.now[:alert] = @document.errors.full_messages.to_sentence
          render :new
        end

      rescue => e
        @epub&.destroy
        flash.now[:alert] = "Failed to generate epub: #{e.message}"
        render :new

      ensure
        tmpfile&.close
        tmpfile&.unlink
      end
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
        text_color: params[:text_color],
        font_family: params[:font_family]
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


  def build_epub(title, authors, content_html)
    xhtml = <<~XHTML
      <?xml version="1.0" encoding="UTF-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>#{CGI.escapeHTML(title)}</title>
          <style>
            body { font-family: Georgia, serif; line-height: 1.7; margin: 2em; }
            h1, h2, h3 { font-weight: bold; }
            blockquote { margin-left: 2em; font-style: italic; }
          </style>
        </head>
        <body>
          <h1>#{CGI.escapeHTML(title)}</h1>
          <p><em>#{CGI.escapeHTML(authors)}</em></p>
          <hr/>
          #{content_html}
        </body>
      </html>
    XHTML

    book = GEPUB::Book.new
    book.identifier = "urn:uuid:#{SecureRandom.uuid}"
    book.add_title(title)
    book.add_creator(authors)
    book.language = "en"

    book.ordered do
      book.add_item("content.xhtml").add_content(StringIO.new(xhtml))
    end

    tmpfile = Tempfile.new(["epub_write_", ".epub"])
    book.generate_epub(tmpfile.path)
    tmpfile
  end

  

  def document_params
      # for whitelisting the parameters for documents to be set
      params.require(:document).permit(:userid, :epubid, :title, :authors, :ispublic, :progress,
                                       :font_size, :line_height, :bg_color, :text_color, :font_family, :locations)
  end

end
