class ExtensionsController < ApplicationController
  include HighlightsHelper 

  skip_before_action :require_user, only: [:modal, :connect]
  after_action :allow_embed_in_iframe, only: [:modal]


  def connect
    unless logged_in?
      render :login_required, layout: false and return
    end

    @token = generate_extension_token
    @extension_origin = params[:origin].to_s

    Rails.logger.info "=== CONNECT SUCCESS ==="
    Rails.logger.info "Token generated (length: #{@token.length})"
    Rails.logger.info "Token preview: #{@token[0..80]}..."  # safe preview

    render layout: false
  end


  def modal
    user = user_from_token

    if user.blank?
      @expired = true
      render :modal, layout: false
      return
    end

    current_user = user
    
    @quote   = params[:quote]&.to_s || ""
    @cfi     = params[:url]&.to_s.presence || "https://example.com"
    @fromauthors = "Web page"
    @fromtitle   = params[:title].presence || "Web Page"


    @giphyApiKey = Rails.env.production? ? ENV["GIPHY_API_KEY"].to_s : "Vsa6RyTveLS9mFOQVsTPmE8vndGnKc6G"

    render layout: false
  end

  private

def allow_embed_in_iframe
  response.headers.delete("X-Frame-Options")
  
  # Allow Giphy images, scripts, etc. in iframe
  response.headers["Content-Security-Policy"] = [
    "frame-ancestors *",
    "img-src 'self' data: https://*.giphy.com https://media.giphy.com",
    "script-src 'self' 'unsafe-inline' https://*.giphy.com",
    "connect-src 'self' https://api.giphy.com",
    "style-src 'self' 'unsafe-inline'"
  ].join("; ")
end
  


  def generate_extension_token
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    payload = {
      user_id: current_user.id.to_s, 
      exp: 7.days.from_now.to_i
    }
    Rails.logger.info "Payload before generate: #{payload.inspect}"
    verifier.generate(payload)
  end


  def uuid_from_url(url)
    return SecureRandom.uuid if url.blank?
    hex = Digest::MD5.hexdigest(url)
    "#{hex[0..7]}-#{hex[8..11]}-#{hex[12..15]}-#{hex[16..19]}-#{hex[20..31]}"
  end

end