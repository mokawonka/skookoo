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
    mode = params.dig(:document, :mode)

    title   = params.dig(:document, :title)&.strip.presence
    authors = params.dig(:document, :authors)&.strip.presence || current_user.name
    ispublic = params.dig(:document, :ispublic) == "1"

    if title.blank?
      flash.now[:alert] = "Title is required."
      render :new, status: :unprocessable_entity and return
    end

    tmpfile = nil
    @epub   = nil

    begin
      if mode == 'essay'
        content = params.dig(:document, :content)&.strip
        if content.blank? || content == '<div><br></div>' || content.strip.empty?
          flash.now[:alert] = "Content is required for essays."
          render :new, status: :unprocessable_entity and return
        end

        tmpfile = build_epub(title, authors, content)

      elsif mode == 'book'
        chapters = params.dig(:document, :chapters) || {}
        valid_chapters = chapters.values.select do |c|
          c[:title].present? && c[:content].present? && c[:content].strip != '<div><br></div>'
        end

        if valid_chapters.empty?
          flash.now[:alert] = "A book must have at least one chapter with title and content."
          render :new, status: :unprocessable_entity and return
        end

        tmpfile = build_book_epub(title, authors, valid_chapters)

      else
        flash.now[:alert] = "Invalid publishing mode."
        render :new, status: :unprocessable_entity and return
      end

      # Common validation: ensure tmpfile is valid
      unless tmpfile && File.exist?(tmpfile.path) && File.size(tmpfile.path) > 100
        raise "EPUB generation failed: invalid or empty file produced"
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
        filename:     "#{title.parameterize.presence || 'document'}.epub",
        content_type: "application/epub+zip"
      )

      unless @epub.save
        flash.now[:alert] = @epub.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity and return
      end

      @document = Document.new(
        userid:   current_user.id,
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
        render :new, status: :unprocessable_entity
      end

    rescue => e
      @epub&.destroy
      error_msg = "Failed to generate EPUB: #{e.message}"
      
      if request.xhr?
        render json: { error: error_msg }, status: :unprocessable_entity
      else
        flash.now[:alert] = error_msg
        render :new, status: :unprocessable_entity
      end
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
    safe_title = CGI.escapeHTML(title.to_s)

    # Convert to clean XHTML
    content_xhtml = Nokogiri::HTML.fragment(content_html.to_s).to_xhtml

    chapter_content = <<~HTML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE html>
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>#{safe_title}</title>
      </head>
      <body>
        <h1>#{safe_title}</h1>
        #{content_xhtml}
      </body>
      </html>
    HTML

    book = GEPUB::Book.new
    book.identifier = "urn:uuid:#{SecureRandom.uuid}"
    book.title      = title
    book.creator    = authors
    book.language   = "en"

    item = book.add_ordered_item("chapter1.xhtml")
    item.add_content(StringIO.new(chapter_content)) 
    # item.toc_text = "Main Content"

    book.spine << item

    tmpfile = Tempfile.new(["#{title.parameterize || 'essay'}", ".epub"])
    tmpfile.binmode
    book.generate_epub(tmpfile.path)

    tmpfile.rewind
    tmpfile
  end


  def build_book_epub(title, authors, chapters_array)
    book = GEPUB::Book.new
    book.identifier = "urn:uuid:#{SecureRandom.uuid}"
    book.title      = title
    book.creator    = authors
    book.language   = "en"

    chapters_array.each_with_index do |chap, idx|
      chap_title = CGI.escapeHTML(chap[:title].to_s.presence || "Chapter #{idx + 1}")
      content_xhtml = Nokogiri::HTML.fragment(chap[:content].to_s).to_xhtml

      chapter_html = <<~HTML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>#{chap_title}</title>
        </head>
        <body>
          <h1>#{chap_title}</h1>
          #{content_xhtml}
        </body>
        </html>
      HTML

      item = book.add_ordered_item("chapter#{idx + 1}.xhtml")
      item.add_content(StringIO.new(chapter_content))
      # item.toc_text = chap[:title].presence || "Chapter #{idx + 1}"

      book.spine << item

    end

    tmpfile = Tempfile.new(["#{title.parameterize || 'book'}", ".epub"])
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
