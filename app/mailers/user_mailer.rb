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


  def new_reply  
      notification = params[:notification] # will be provided via `with`
      @reply = notification.params[:reply]
      @user  = notification.recipient

      host = "skookoo.com"

      @url = Rails.application.routes.url_helpers.highlight_url(
        @reply.highlightid,
        reply: @reply.id,
        host: host
      )

      author_name = User.where(id: @reply.userid).pick(:username) || "Someone"


      mail(to: @user.email, subject: "New reply from #{author_name}")
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


  def new_highlight
    notification = params[:notification]

    @highlight = notification.params[:highlight]
    @user      = notification.recipient

    author_name = User.where(id: @highlight.userid).pick(:username) || "Someone"

    host = "skookoo.com"

    @url = Rails.application.routes.url_helpers.highlight_url(
      @highlight.id,
      host: host
    )

    mail(
      to:      @user.email,
      subject: "#{author_name} highlighted from #{@highlight.fromtitle.truncate(40)}"
    )
  end


end