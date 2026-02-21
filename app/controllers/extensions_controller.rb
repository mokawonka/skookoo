class ExtensionsController < ApplicationController
  include HighlightsHelper

  def modal
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

  def uuid_from_url(url)
    return SecureRandom.uuid if url.blank?
    hex = Digest::MD5.hexdigest(url)
    "#{hex[0..7]}-#{hex[8..11]}-#{hex[12..15]}-#{hex[16..19]}-#{hex[20..31]}"
  end
end