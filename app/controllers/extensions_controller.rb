class ExtensionsController < ApplicationController
  include HighlightsHelper

  skip_before_action :require_user, only: [:modal, :token]

  # Allow extension modal to be embedded in iframes on any page (Chrome extension)
  after_action :allow_embed_in_iframe, only: [:modal, :token]

  def token
    unless logged_in?
      redirect_to login_path, alert: "Log in first to connect the extension."
      return
    end
    @token = generate_extension_token
    render :token, layout: false
  end

  def modal
    # Accept either session cookie (when same-origin) or token (when cross-origin, e.g. extension)
    unless logged_in?
      if (user = user_from_extension_token)
        session[:user_id] = user.id
      else
        render :login_required, layout: false
        return
      end
    end

    @quote = params[:quote]
    @url = params[:url].to_s
    @title = params[:title].to_s.presence || "Web Page"

    # For web highlights: synthetic docid (UUID from URL), cfi = URL, fromauthors = "Web"
    @docid = uuid_from_url(@url)
    @cfi = @url
    @fromauthors = "Web"
    @fromtitle = @title

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
    verifier.generate(
      { user_id: current_user.id, exp: 24.hours.from_now.to_i },
      expires_in: 24.hours
    )
  end

  def user_from_extension_token
    token = params[:token].to_s.strip
    return nil if token.blank?
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    data = verifier.verified(token) rescue nil
    return nil unless data && data[:exp].to_i > Time.current.to_i
    User.find_by(id: data[:user_id])
  end

  def uuid_from_url(url)
    return SecureRandom.uuid if url.blank?
    hex = Digest::MD5.hexdigest(url)
    "#{hex[0..7]}-#{hex[8..11]}-#{hex[12..15]}-#{hex[16..19]}-#{hex[20..31]}"
  end
end