class FollowRequestNotifier < Noticed::Base
  deliver_by :database

  param :follower
  param :followed_user

  # This is what your partial is calling: notification.event.message
  def message
    "#{params[:follower].name} sent you a follow request"
  end

  def url
    # You can change this later to a dedicated "Follower Requests" page
    user_path(params[:follower].username)
  end

  def avatar
    if params[:follower].avatar.attached?
      url_for(params[:follower].avatar)
    else
      "default-avatar.svg"   # or your default avatar path
    end
  end
end