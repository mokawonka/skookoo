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
    end

    # def available
    #   epubs = Epub.where(public_domain: true).order("RANDOM()").limit(100)

    #   render json: epubs.as_json(
    #     only:    [:id, :title, :authors, :public_domain],
    #     methods: [:cover_url, :filename]
    #   )
    # end

    def available

      @lang = params[:lang]&.strip || "en"

      seed = session.fetch(:epub_seed) { rand(1_000_000_000) }.tap do |s|
        session[:epub_seed] = s unless session.key?(:epub_seed)
      end
      
      @pagy, epubs = pagy(
        Epub.where(public_domain: true, lang: @lang).order(Arel.sql("md5(id::text || '#{seed}')")),
        items: 10,
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
          items: 10,
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

      # save epub to db
        @epub = Epub.new(epub_params)


        filename = @epub.epub_on_disk
        if (filename == -1) # checking type on server
          flash.now[:alert] = "File must be an epub"
          render :new
          return
        end


        begin
          reader = EPUB::Parser.parse(filename)
        rescue
          respond_to do |format|
              format.js {render inline: "$('#uploadStatus').html('<p style=color:red class=pt-3>Your epub file seems corrupted. Please try again with another one.</p>');" }
          end
          
        else

          @epub.title = reader.metadata.title
          @epub.authors = reader.metadata.creators[0].to_s.split(";").join(", ")
          @epub.lang = reader.metadata.languages[0].content
          @epub.sha3 = SHA3::Digest.file(filename).hexdigest
          @epub.public_domain = false

          # get cover pic
          if reader.cover_image
    
            temp_dir = File.join(Dir.tmpdir, "ebook" + $$.to_s)
            Zip::File.open(filename) do |zipfile|
              zipfile.each do |file|
    
                if File.basename(file.to_s) == File.basename(reader.cover_image.href)
    
                  f_path = File.join(temp_dir, file.name)
                  FileUtils.mkdir_p(File.dirname(f_path))
                  zipfile.extract(file, f_path)
    
                  @epub.cover = f_path
    
                  #deleting tmp folder
                  FileUtils.rm_rf temp_dir
                end
              end
            end
    
          end
    
          if @epub.save
                # create document
                @document = Document.new
                @document.userid  = session[:user_id]      
                @document.epubid  = @epub.id
                @document.title   = @epub.title
                @document.authors = @epub.authors
                @document.ispublic = @epub.public_domain

                if @document.save
                    flash[:notice] = "Document added successfully."
                    respond_to do |format|
                      format.html { redirect_to documents_path }
                      format.js do
                        render js: "window.location = '#{documents_path}';"
                      end
                    end
                else
                    flash.now[:notice] = "Document creation failed"
                    render :file => 'public/500.html'
                end
          else
              flash.now[:notice] = "Epub upload failed."
              render :file => 'public/500.html'
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
  