# frozen_string_literal: true

module Api
  module V1
    class DocumentsController < Api::BaseController
      before_action :authenticate_agent!
      before_action :require_claimed_agent!
      before_action :require_agent_user!

      # GET /api/v1/documents — list documents for the agent's linked user (for picking docid when creating highlights)
      def index
        documents = Document
          .where(userid: @current_agent.userid)
          .includes(:epub)
          .order(Arel.sql("COALESCE(last_accessed_at, updated_at) DESC NULLS LAST"))

        render_success(
          documents: documents.map { |doc| document_response(doc) }
        )
      end

      # GET /api/v1/documents/:id — show one document (must belong to agent's user)
      def show
        doc = Document.find_by!(id: params[:id], userid: @current_agent.userid)
        render_success(document: document_response(doc))
      end

      # GET /api/v1/documents/:id/read — get a temporary URL to read (download) the document's EPUB content
      def read
        doc = Document.where(userid: @current_agent.userid).includes(:epub).find(params[:id])
        epub = doc.epub

        unless epub&.epub_file&.attached?
          return render_error("Document has no readable content", status: :not_found)
        end

        expires_in = 15.minutes
        read_url = url_helpers.rails_blob_url(epub.epub_file, expires_in: expires_in)

        render_success(
          document: document_response(doc),
          read_url: read_url,
          expires_in_seconds: expires_in.to_i
        )
      end

      # POST /api/v1/documents/:id/resolve_cfi — resolve a text quote to the correct EPUB CFI (for creating highlights)
      def resolve_cfi
        doc = Document.where(userid: @current_agent.userid).includes(:epub).find(params[:id])
        epub = doc.epub

        unless epub&.epub_file&.attached?
          return render_error("Document has no readable content", status: :not_found)
        end

        quote = resolve_cfi_params[:quote].to_s.strip
        if quote.blank?
          return render_error("quote is required", hint: "Send the exact text to locate in the document", status: :unprocessable_entity)
        end

        result = CfiResolverService.call(epub.epub_file.blob, quote)

        unless result.success?
          return render_error(
            "Quote not found in document",
            hint: "Use the exact text as it appears in the EPUB (try normalizing spaces)",
            status: :not_found
          )
        end

        render_success(
          document: document_response(doc),
          cfi: result.cfi,
          quote_found: result.quote_found,
          fromtitle: doc.title,
          fromauthors: doc.authors
        )
      end

      private

      def resolve_cfi_params
        { quote: params[:quote].presence || params.dig(:highlight, :quote) }
      end

      def authenticate_agent!
        @current_agent = Agent.authenticate_by_api_key(auth_header)
        return render_error("Missing or invalid API key", hint: "Use Authorization: Bearer YOUR_API_KEY", status: :unauthorized) unless @current_agent
      end

      def require_claimed_agent!
        return render_error("Agent must be claimed to access documents", status: :forbidden) unless @current_agent&.claimed?
      end

      def require_agent_user!
        return render_error("Agent is not linked to a user", status: :forbidden) if @current_agent&.userid.blank?
      end

      def auth_header
        request.authorization
      end

      def document_response(doc)
        {
          id: doc.id,
          docid: doc.id,
          title: doc.title,
          authors: doc.authors,
          epubid: doc.epubid,
          ispublic: doc.ispublic,
          progress: doc.progress
        }
      end

      def url_helpers
        Rails.application.routes.url_helpers
      end
    end
  end
end
