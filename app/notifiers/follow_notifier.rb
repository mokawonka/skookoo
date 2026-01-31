class FollowNotifier < Noticed::Event
  # Deliver notifications
  deliver_by :database
  deliver_by :email, mailer: "UserMailer", 
                     method: :new_follower, 
                     with: ->(event) { { notification: event } },
                     if: -> { recipient&.emailnotifications? }

  # The message shown in notifications
  def message
    follower = params[:follower]
    "#{follower.username} started following you!"
  end

  # URL to the follower’s profile (optional)
  def url
    follower = params[:follower]
    user_path(follower.username)
  end

  # Optional avatar method if you display avatars in notifications
  def avatar
    follower = params[:follower]
    if follower&.avatar&.attached?
      Rails.application.routes.url_helpers.rails_representation_url(
        follower.avatar.variant(resize_to_limit: [32, 32]).processed,
        only_path: true
      )
    else
      "default-avatar.svg"
    end
  end
end