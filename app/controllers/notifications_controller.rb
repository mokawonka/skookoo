class NotificationsController < ApplicationController

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back(fallback_location: root_path)
    # or respond with turbo_stream to clear UI if you want
  end
  

  def clear_all
    current_user.notifications.destroy_all
    redirect_back(fallback_location: root_path)
  end


end