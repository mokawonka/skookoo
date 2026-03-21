class HighlightNotifier < Noticed::Event

  deliver_by :database
  deliver_by :email,
                mailer: "UserMailer",
                method: :new_highlight,
                with: ->(event) { { notification: event } },
                if: -> { recipient&.emailnotifications? }

  def message
    highlight    = params[:highlight]
    author_name  = User.where(id: highlight.userid).pick(:username) || "Someone"
    "#{author_name} highlighted from #{highlight.fromtitle.truncate(40)}"
  end

  def url
    highlight_path(params[:highlight].id)
  end

  def avatar
    author = User.find_by(id: params[:highlight].userid)

    if author&.avatar&.attached?
      Rails.application.routes.url_helpers.rails_representation_url(
        author.avatar.variant(resize_to_limit: [32, 32]).processed,
        only_path: true
      )
    else
      default_avatar_url(author)
    end
  end

  private

  def default_avatar_url(user = nil)
    "default-avatar.svg"
  end

end