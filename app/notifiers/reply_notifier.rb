# app/notifiers/reply_notifier.rb
class ReplyNotifier < Noticed::Event

  deliver_by :database
  deliver_by :turbo_broadcast, class: "DeliveryMethods::TurboBroadcast"

  # Define methods here — Noticed delegates them to the notification instance
  def message
    reply = params[:reply]
    author_name = User.where(id: reply.userid).pick(:username) || "Someone"
    "New reply from #{author_name}: #{reply.content.to_plain_text.truncate(60)}"
  end

  def url
    highlight_path(params[:reply].highlightid) + "?reply=#{params[:reply].id}"
  end

   def avatar
    reply = params[:reply]
    author = User.find_by(id: reply.userid)

    if author&.avatar&.attached?
      # author.avatar.variant(resize_to_limit: [32, 32])
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
    "/assets/default-avatar.svg"  
  end

end