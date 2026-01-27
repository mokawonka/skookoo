class ReplyMailer < ApplicationMailer
  # No arguments here
  def notify
    
    notification = params[:notification] # will be provided via `with`
    @reply = notification.params[:reply]
    @user  = notification.recipient

    host = "mokawonka.space"

    @url = Rails.application.routes.url_helpers.highlight_url(
      @reply.highlightid,
      reply: @reply.id,
      host: host
    )

    author_name = User.where(id: @reply.userid).pick(:username) || "Someone"


    mail(to: @user.email, subject: "New reply from #{author_name}")
  end
end