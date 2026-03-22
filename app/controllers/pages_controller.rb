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

    if logged_in?
      # Include reposts from everyone for logged-in users
      highlights = build_feed_with_reposts(Highlight.all, User.all.pluck(:id), sort)
    else
      highlights = sort == 'top' ? Highlight.all.order(score: :desc) : Highlight.all.order(created_at: :desc)
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
              .where(
                "quote ILIKE :q OR fromauthors ILIKE :q OR fromtitle ILIKE :q",
                q: "%#{q}%"
              )
              .order(Arel.sql(
                "GREATEST(
                  similarity(quote, #{ActiveRecord::Base.connection.quote(q)}),
                  similarity(fromauthors, #{ActiveRecord::Base.connection.quote(q)}),
                  similarity(fromtitle, #{ActiveRecord::Base.connection.quote(q)})
                ) DESC"
              )).limit(5)

    render partial: "pages/live_results"

  end


  def search
    @query = params[:query]

    if @query.blank?
      redirect_to root_path
    else
      @users = User
        .where("username % :q OR name % :q", q: @query)
        .order(Arel.sql("GREATEST(similarity(username, #{ActiveRecord::Base.connection.quote(@query)}), similarity(name, #{ActiveRecord::Base.connection.quote(@query)})) DESC"))
        .limit(6)

      @fromhighlights = Highlight
            .where(
              "quote ILIKE :q OR fromauthors ILIKE :q OR fromtitle ILIKE :q",
              q: "%#{@query}%"
            )
            .order(Arel.sql(
              "GREATEST(
                similarity(quote, #{ActiveRecord::Base.connection.quote(@query)}),
                similarity(fromauthors, #{ActiveRecord::Base.connection.quote(@query)}),
                similarity(fromtitle, #{ActiveRecord::Base.connection.quote(@query)})
              ) DESC"
            ))

      @pagy, @highlights = pagy(@fromhighlights, items: 21)
    end
  end



  def following
    following_ids = current_user.following || []
    sort = params[:sort] || 'new'

    if following_ids.empty?
      @pagy, @records = pagy(Highlight.none, items: 21)
      return respond_to { |f| f.js }
    end

    @pagy, @records = pagy(build_feed_with_reposts(nil, following_ids, sort), items: 21)

    respond_to do |format|
      format.js
    end
  end

  private


  def build_feed_with_reposts(_, user_ids, sort)
    sort_expr = sort == 'top' ? 'score DESC' : 'sort_at DESC'

    own = Highlight
            .where(userid: user_ids)
            .select("highlights.*, highlights.created_at AS sort_at, highlights.score AS sort_score, NULL::uuid AS reposted_by_id")

    reposted = Highlight
                .joins(:reposts)
                .where(reposts: { user_id: user_ids })
                .select("highlights.*, reposts.created_at AS sort_at, highlights.score AS sort_score, reposts.user_id AS reposted_by_id")

    Highlight.from(
      "(#{own.to_sql} UNION ALL #{reposted.to_sql}) AS highlights"
    ).order(Arel.sql(sort_expr))
  end

end