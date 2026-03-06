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
    title   = params.dig(:document, :title)&.strip.presence
    authors = params.dig(:document, :authors)&.strip.presence || current_user.name
    content = params.dig(:document, :content)&.strip
    ispublic = params.dig(:document, :ispublic) == "1"

    if title.blank? || content.blank?
      flash.now[:alert] = "Title and content are required."
      render :new, status: :unprocessable_entity and return
    end

    tmpfile = nil
    @epub   = nil

    begin
      tmpfile = build_epub(title, authors, content) 

      unless tmpfile && File.exist?(tmpfile.path) && File.size(tmpfile.path) > 0
        raise "EPUB generation failed: no valid file produced"
      end

      sha3_digest = SHA3::Digest.file(tmpfile.path).hexdigest

      @epub = Epub.new(
        title:         title,
        authors:       authors,
        lang:          "en",
        public_domain: false,
        sha3:          sha3_digest
      )

      @epub.epub_file.attach(
        io:           File.open(tmpfile.path),
        filename:     "#{title.parameterize}.epub",
        content_type: "application/epub+zip"
      )

      unless @epub.save
        flash.now[:alert] = @epub.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity and return
      end

      @document = Document.new(
        userid:     current_user.id,          
        epubid:     @epub.id,
        title:    title,
        authors:  authors,
        ispublic: ispublic
      )

      if @document.save
        redirect_to document_path(@document), notice: "Published successfully!"
      else
        @epub.destroy
        flash.now[:alert] = @document.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end

    rescue => e
      @epub&.destroy
      flash.now[:alert] = "Failed to generate EPUB: #{e.message}"
      render :new, status: :unprocessable_entity

    ensure
      tmpfile&.close
      tmpfile&.unlink if tmpfile
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

    safe_title = CGI.escapeHTML(title)

    # Convert HTML → valid XHTML for EPUB
    content_html = Nokogiri::HTML::DocumentFragment.parse(content_html).to_xhtml

    book = GEPUB::Book.new
    book.identifier = "urn:uuid:#{SecureRandom.uuid}"
    book.title      = safe_title
    book.creator    = authors
    book.language   = "en"

    chapter_content = <<~HTML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>#{safe_title}</title>
    </head>
    <body>
      <h1>#{safe_title}</h1>
      #{content_html}
    </body>
    </html>
    HTML

    item = book.add_item("chapter1.xhtml")
    item.add_content(StringIO.new(chapter_content))

    book.spine << item

    tmpfile = Tempfile.new(["#{title.parameterize}", ".epub"])
    tmpfile.binmode

    book.generate_epub(tmpfile.path)

    tmpfile.rewind
    tmpfile
  end
  

  def document_params
      # for whitelisting the parameters for documents to be set
      params.require(:document).permit(:userid, :epubid, :title, :authors, :ispublic, :progress,
                                       :font_size, :line_height, :bg_color, :text_color, :font_family, :locations)
  end

end
