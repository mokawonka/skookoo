class RepostsController < ApplicationController
  before_action :set_highlight

  def create
    current_user.reposts.find_or_create_by(highlight: @highlight)
    respond_to { |f| f.js }
  end

  def destroy
    current_user.reposts.find_by(highlight: @highlight)&.destroy
    respond_to { |f| f.js }
  end

  private

  def set_highlight
    @highlight = Highlight.find(params[:highlight_id])
  end
end