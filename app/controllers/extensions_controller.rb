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

    @current_user = user
    @quote   = params[:quote]&.to_s || ""
    @url     = params[:url]&.to_s.presence || "https://example.com"
    @title   = params[:title].presence || "Web Page"

    @docid       = uuid_from_url(@url) rescue SecureRandom.uuid
    @cfi         = @url
    @fromauthors = "Web"
    @fromtitle   = @title

    @giphyApiKey = Rails.env.production? ? ENV["GIPHY_API_KEY"].to_s : "Vsa6RyTveLS9mFOQVsTPmE8vndGnKc6G"

    render layout: false
  end

  private

  def allow_embed_in_iframe
    response.headers.delete("X-Frame-Options")
    response.headers["Content-Security-Policy"] = "frame-ancestors *"
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



  def user_from_token
    token = params[:token].to_s
    return nil if token.blank?

    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)

    begin
      data = verifier.verify(token)
      Rails.logger.info "Token verified - full data: #{data.inspect}"

      # Handle exp as string or integer (verifier can return string)
      exp_raw = data[:exp] || data['exp']
      exp = exp_raw.to_i
      if exp.zero? || exp < Time.current.to_i
        Rails.logger.warn "Token expired or invalid exp! raw exp: #{exp_raw.inspect}, parsed: #{exp}"
        return nil
      end

      # Handle user_id as string or integer
      user_id = (data[:user_id] || data['user_id']).to_s
      user = User.find_by(id: user_id)
      Rails.logger.info "User found: #{user&.id || 'not found'} (looked for id: #{user_id})"
      user
    rescue => e
      Rails.logger.error "Token verification FAILED: #{e.class} - #{e.message}"
      nil
    end
  end


  def uuid_from_url(url)
    return SecureRandom.uuid if url.blank?
    hex = Digest::MD5.hexdigest(url)
    "#{hex[0..7]}-#{hex[8..11]}-#{hex[12..15]}-#{hex[16..19]}-#{hex[20..31]}"
  end

end