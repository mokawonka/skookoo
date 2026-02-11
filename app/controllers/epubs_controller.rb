class EpubsController < ApplicationController  
    before_action :authorize_user!

    def index

    end
  
    def show
      @epub = Epub.find(params[:id])
      
      if @epub.file.attached?
        # Option A: Let browser try to open it (most readers will download anyway)
        redirect_to rails_blob_url(@epub.file), allow_other_host: false
      else
        head :not_found
      end
    end
  


    def new
        @epub = Epub.new

        @englishCount = Epub.where(public_domain: true, lang: "en").count
        @frenchCount = Epub.where(public_domain: true, lang: "fr").count

    end
    

    def available

      @lang = params[:lang]&.strip || "en"

      seed = session.fetch(:epub_seed) { rand(1_000_000_000) }.tap do |s|
        session[:epub_seed] = s unless session.key?(:epub_seed)
      end

      @pagy, epubs = pagy(
        Epub.where(public_domain: true, lang: @lang).order(Arel.sql("md5(id::text || '#{seed}')")),
        items: 1,
        page: params[:page]&.to_i || 1
      )

      render json: {
        books: epubs.as_json(
          only:    [:id, :title, :authors, :public_domain],
          methods: [:cover_url, :filename]
        ),
        pagination: {
          current_page:  @pagy.page,
          total_pages:   @pagy.pages,
          total_count:   @pagy.count,
          next_page_url: @pagy.next ? url_for(request.query_parameters.merge(page: @pagy.next)) : nil
        }
      }
    
    end

    def search

        @query = params[:query]&.strip
        @lang  = params[:lang]&.strip

        if @query.blank?
          render json: { error: "Query cannot be blank" }, status: :bad_request
          return
        end

        scope = Epub.where(public_domain: true)
        scope = scope.where(lang: @lang) if @lang.present?

        @pagy, epubs = pagy(
          scope.global_search(@query),
          items: 1,
          page: params[:page]&.to_i || 1
        )

        render json: {
          books: epubs.as_json(
            only:    [:id, :title, :authors, :public_domain],
            methods: [:cover_url, :filename]
          ),
          pagination: {
            current_page:  @pagy.page,
            total_pages:   @pagy.pages,
            total_count:   @pagy.count,
            next_page_url: @pagy.next ? url_for(request.query_parameters.merge(page: @pagy.next)) : nil
          }
        }

    end



    def create
      @epub = Epub.new(epub_params)

      # === File type validation ===
      unless @epub.epub_file.attached? && @epub.epub_file.content_type == "application/epub+zip"
        respond_to do |format|
          format.js do
            render inline: <<-JS
              $('#uploadStatus').html('<p style="color:red;" class="pt-3">File must be an .epub file</p>');
              $('input[type="file"]').val('');
              $('input[type="file"]').prop('disabled', false);
            JS
          end
          format.html do
            flash.now[:alert] = "File must be an .epub file"
            render :new
          end
        end
        return
      end

      # === Rest of the code (save + parsing) ===
      if @epub.save
        begin
          temp_path = nil
          @epub.epub_file.blob.open do |tempfile|
            temp_path = tempfile.path

            reader = EPUB::Parser.parse(temp_path)

            @epub.title   = reader.metadata.title
            @epub.authors = reader.metadata.creators.map(&:to_s).join(", ")
            @epub.lang    = reader.metadata.languages.first&.content || "en"
            @epub.sha3    = SHA3::Digest.file(temp_path).hexdigest
            @epub.public_domain = false

            if reader.cover_image
              Epub.extract_cover_from_epub(temp_path, reader.cover_image.href, @epub)
            end

            @epub.save!
          end

          # Create Document...
          @document = Document.new(
            userid: session[:user_id],
            epubid: @epub.id,
            title: @epub.title,
            authors: @epub.authors,
            ispublic: false
          )

          if @document.save
            respond_to do |format|
              format.html { redirect_to documents_path }
              format.js   { render js: "window.location = '#{documents_path}';" }
            end
          else
            @epub.destroy
            respond_to do |format|
              format.js { render inline: "$('#uploadStatus').html('<p style=\"color:red;\" class=\"pt-3\">Document creation failed.</p>');" }
            end
          end

        rescue => e
          @epub.destroy
          respond_to do |format|
            format.js { render inline: "$('#uploadStatus').html('<p style=\"color:red;\" class=\"pt-3\">Your epub file seems corrupted. Please try again.</p>');" }
          end
        end
      else
        respond_to do |format|
          format.js { render inline: "$('#uploadStatus').html('<p style=\"color:red;\" class=\"pt-3\">Failed to upload file.</p>');" }
        end
      end
    end



    def createfromdb

        @epub = Epub.find(params[:id])
        
        if @epub != nil
            
            @document = Document.new
            @document.userid = session[:user_id]      
            @document.epubid = @epub.id
            @document.title = @epub.title
            @document.authors = @epub.authors
            @document.ispublic = @epub.public_domain
        
            if @document.save
              flash[:notice] = "Document added successfully."
              head :ok   # or render json: { success: true } — anything lightweight
            else
              flash.now[:alert] = "Document creation failed"
              render status: :unprocessable_entity, plain: "Error"
            end
            
        end    
    end


    def check_presence
        
        @hash = params[:sha3]

        @epubid = nil

        Epub.all.each do |e|
            if @hash == e.sha3
                @epubid = e.id
                break
            end
        end
        
        respond_to do |format|
            format.js
        end

    end

  
  
    def destroy
      Epub.find(params[:id]).destroy!
      flash.now[:notice] = "Epub deleted successfully"
    end
  
  
    private
  
    def epub_params
        params.require(:epub).permit(:epub_file, :cover_pic, :title, :authors, :lang, :sha3, :public_domain)
    end
  
  end
  