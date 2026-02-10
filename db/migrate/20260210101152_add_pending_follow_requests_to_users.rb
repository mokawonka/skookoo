class AddPendingFollowRequestsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :pending_follow_requests, :text, default: "[]"
  end
end