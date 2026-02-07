class PagesController < ApplicationController
  skip_before_action :require_user, only: [:login, :home, :search]

  def login
    if logged_in?
      redirect_to user_path(current_user.username)
    end
  end




  def home
    @pagy, @records = pagy(Highlight.all, items: 21)

    respond_to do |format|
      format.js
      format.html
    end

  end



  def search

    @query = params[:query]

    if @query.blank?
      redirect_to root_path
    else

      @fromhighlights = Highlight.global_search(@query)
      
      @pagy, @highlights = pagy(@fromhighlights, items: 21)

    end

  end

  

  def filter
    following_ids = current_user.following || []

    @bulkfiltered = Highlight
      .where(userid: following_ids)
      .order(created_at: :desc)

    @pagy, @filtered = pagy(@bulkfiltered, items: 21)

    respond_to do |format|
      format.js
    end
  end

end
