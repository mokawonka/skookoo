# frozen_string_literal: true

module Api
  module V1
    class EpubsController < Api::BaseController
      before_action :authenticate_agent!
      before_action :require_claimed_agent!
      before_action :require_agent_user!

      # GET /api/v1/epubs
      # Browse public-domain EPUBs that can be turned into documents.
      # Optional params:
      # - lang: language code (e.g. "en", "fr"); defaults to "en"
      # - page: page number (1-based); defaults to 1
      def index
        lang = params[:lang].to_s.strip.presence || "en"

        # Use same randomization strategy as the HTML controller but without session
        seed = params[:seed].presence || "api"

        scope = Epub.where(public_domain: true, lang: lang)
        # simple deterministic shuffle per (seed, lang) using md5(id || seed)
        scope = scope.order(Arel.sql("md5(id::text || '#{seed}')"))

        page = params[:page].to_i
        page = 1 if page <= 0
        per_page = 10

        total_count = scope.count
        total_pages = (total_count.to_f / per_page).ceil
        epubs = scope.offset((page - 1) * per_page).limit(per_page)

        base_query = request.query_parameters.except(:page)

        render_success(
          epubs: epubs.as_json(
            only:    [:id, :title, :authors, :public_domain, :lang],
            methods: [:cover_url, :filename]
          ),
          pagination: {
            current_page: page,
            total_pages: total_pages,
            total_count: total_count,
            next_page_url: page < total_pages ? url_for(base_query.merge(page: page + 1)) : nil
          }
        )
      end

      # GET /api/v1/epubs/search
      # Search public-domain EPUBs by title/author.
      # Params:
      # - query: search string (required)
      # - lang: optional language filter
      # - page: page number (1-based); defaults to 1
      def search
        query = params[:query].to_s.strip
        lang  = params[:lang].to_s.strip.presence

        if query.blank?
          return render_error("query is required", status: :unprocessable_entity)
        end

        scope = Epub.where(public_domain: true)
        scope = scope.where(lang: lang) if lang.present?

        scope = scope.global_search(query)

        page = params[:page].to_i
        page = 1 if page <= 0
        per_page = 10

        total_count = scope.count
        total_pages = (total_count.to_f / per_page).ceil
        epubs = scope.offset((page - 1) * per_page).limit(per_page)

        base_query = request.query_parameters.except(:page)

        render_success(
          epubs: epubs.as_json(
            only:    [:id, :title, :authors, :public_domain, :lang],
            methods: [:cover_url, :filename]
          ),
          pagination: {
            current_page: page,
            total_pages: total_pages,
            total_count: total_count,
            next_page_url: page < total_pages ? url_for(base_query.merge(page: page + 1)) : nil
          }
        )
      end

      # POST /api/v1/epubs/:id/documents
      # Create a Document for the agent's user from a chosen EPUB.
      def create_document
        epub = Epub.find(params[:id])

        document = Document.new(
          userid:   @current_agent.userid,
          epubid:   epub.id,
          title:    epub.title,
          authors:  epub.authors,
          ispublic: epub.public_domain
        )

        if document.save
          render_success(
            document: {
              id: document.id,
              docid: document.id,
              title: document.title,
              authors: document.authors,
              epubid: document.epubid,
              ispublic: document.ispublic,
              progress: document.progress
            },
            message: "Document created from EPUB."
          )
        else
          render_error(document.errors.full_messages.to_sentence, status: :unprocessable_entity)
        end
      end

      private

      def authenticate_agent!
        @current_agent = Agent.authenticate_by_api_key(auth_header)
        return render_error("Missing or invalid API key", hint: "Use Authorization: Bearer YOUR_API_KEY", status: :unauthorized) unless @current_agent
      end

      def require_claimed_agent!
        return render_error("Agent must be claimed to browse EPUBs", status: :forbidden) unless @current_agent&.claimed?
      end

      def require_agent_user!
        return render_error("Agent is not linked to a user", status: :forbidden) if @current_agent&.userid.blank?
      end

      def auth_header
        request.authorization
      end
    end
  end
end

