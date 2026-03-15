class PagesController < ApplicationController
  skip_before_action :require_user, only: [:login, :home, :search, :about, :live]

  def login
    if logged_in?
      redirect_to root_path
    else
      session[:return_to] = params[:return_to] if params[:return_to].present?
    end
  end


  def home
    sort = params[:sort] || 'new'

    highlights = Highlight.all
    if sort == 'top'
      highlights = highlights.order(score: :desc)
    else
      highlights = highlights.order(created_at: :desc)
    end

    @pagy, @records = pagy(highlights, items: 21)

    respond_to do |format|
      format.js 
      format.html
    end
  end



  def live

    q = params[:q]

    return render html: "" if q.blank?

    @users = User
      .where("username % :q OR name % :q", q: q)
      .order(Arel.sql("GREATEST(similarity(username, #{ActiveRecord::Base.connection.quote(q)}), similarity(name, #{ActiveRecord::Base.connection.quote(q)})) DESC"))
      .limit(5)

    @highlights = Highlight
          .where("quote ILIKE ?", "%#{q}%")
          .order(Arel.sql("similarity(quote, #{ActiveRecord::Base.connection.quote(q)}) DESC"))
          .limit(5)

    render partial: "pages/live_results"

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



  def following
    following_ids = current_user.following || []

    sort = params[:sort] || 'new' 

    bulkfiltered = Highlight.where(userid: following_ids)
    
    if sort == 'top'
      bulkfiltered = bulkfiltered.order(score: :desc) 
    else
      bulkfiltered = bulkfiltered.order(created_at: :desc)
    end

    @pagy, @records = pagy(bulkfiltered, items: 21)

    respond_to do |format|
      format.js 
    end
  end
end