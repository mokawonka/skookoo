class PagesController < ApplicationController
  

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

    @userid = params[:followerid]
    @following = User.find(@userid).following

    @bulkfiltered = Highlight.where(userid: @following)
    @pagy, @filtered = pagy(@bulkfiltered, items: 21)

    respond_to do |format|
      format.js
    end

  end


end
