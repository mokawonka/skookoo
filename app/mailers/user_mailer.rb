class UserMailer < ApplicationMailer


  def new_follower
    notification = params[:notification]

    @user     = notification.recipient          # the followed user
    @follower = notification.params[:follower]  # the user who followed

    host = "skookoo.com"

    @url = Rails.application.routes.url_helpers.user_url(
      @follower.username,
      host: host
    )

    mail(
      to: @user.email,
      subject: "#{@follower.username} started following you"
    )
  end


  def reset_email(user)
    @user = user
    @reset_url = edit_password_reset_url(@user.reset_password_token)
    mail(to: @user.email, subject: "Reset your password")
  end


  
  def new_writing
    notification = params[:notification]

    @author   = notification.params[:author]
    @document = notification.params[:document]
    @recipient = notification.recipient

    mail(
      to:      @recipient.email,
      subject: "#{@author.username} published a new #{@document.nature}"
    )
  end


end