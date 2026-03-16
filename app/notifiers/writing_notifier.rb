class WritingNotifier < Noticed::Event
    deliver_by :database
    deliver_by :email, mailer: "UserMailer",
                    method: :new_writing,
                    with: ->(event) { { notification: event } },
                    if: -> { recipient&.emailnotifications? }

  def message
    author   = params[:author]
    document = params[:document]
    return "New writing published" unless author && document
    "#{author.username} published a new #{document.nature}: \"#{document.title}\""
  end

  def url
    document = params[:document]
    return "/" unless document
    document_path(document)
  end

  def avatar
    author = params[:author]
    if author&.avatar&.attached?
      Rails.application.routes.url_helpers.rails_representation_url(
        author.avatar.variant(resize_to_limit: [32, 32]).processed,
        only_path: true
      )
    else
      "default-avatar.svg"
    end
  end
end