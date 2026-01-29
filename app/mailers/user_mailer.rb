class UserMailer < ApplicationMailer
  def new_follower
    notification = params[:notification]

    @user     = notification.recipient          # the followed user
    @follower = notification.params[:follower]  # the user who followed

    host = "mokawonka.space"

    @url = Rails.application.routes.url_helpers.user_url(
      @follower.username,
      host: host
    )

    mail(
      to: @user.email,
      subject: "#{@follower.username} started following you"
    )
  end
end