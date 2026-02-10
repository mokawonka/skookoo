class FollowApprovedNotifier < Noticed::Base
  deliver_by :database

  param :follower      # the person who requested to follow
  param :followed_user # the private user who approved

  def message
    "#{params[:followed_user].name} approved your follow request"
  end

  def url
    user_path(params[:followed_user])
  end

  def avatar
    if params[:followed_user].avatar.attached?
      url_for(params[:followed_user].avatar)
    else
      "default-avatar.svg"
    end
  end
end