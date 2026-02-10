class User < ApplicationRecord


    has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
    has_many :agents, foreign_key: :userid, dependent: :nullify

    has_one_attached :avatar
    has_secure_password

    attribute :mana, :integer, default: 1
    attribute :darkmode, :boolean, default: false
    attribute :allownotifications, :boolean, default: true
    attribute :emailnotifications, :boolean, default: true  
    attribute :font, :string, default: 'League Spartan Bold'


    serialize :votes,     type: Hash, coder: JSON
    serialize :following, type: Array, coder: JSON
    serialize :followers, type: Array, coder: JSON
    serialize :pending_follow_requests, type: Array, coder: JSON


    validates :email, email: true, presence: true, uniqueness: {message: "already taken"}
    
    validates :username, presence: true, uniqueness: {message: "already taken"}, :length => {:minimum => 2, :message => "must contain at least 2 characters"}
    
    validates :password, presence: true, :length => {:minimum => 3, :message => "length must be at least 3"}, :if => :password
    validates :password, confirmation: { case_sensitive: true }, :if => :password


    attr_accessor :previous_followers

    before_save :store_previous_followers
    after_save :notify_new_followers


    def getvote(entityid)
        if votes.key?(entityid)
            if votes[entityid] == "1"
                return 1
            elsif votes[entityid] == "-1"
                return -1
            #else
                #return 0 #should never be the case though
            end
        else
            return 0
        end
    end


    def private?
        private_profile
    end

    def approved_follower?(viewer)
        return false if viewer.nil?
        following.include?(viewer.id)   # means they are accepted
    end

    def has_pending_follow_request_from?(viewer)
        return false if viewer.nil?
        pending_follow_requests.include?(viewer.id)
    end

    private
    
    def store_previous_followers
        # Save a copy of the followers before saving
        self.previous_followers = followers_was || []
    end

    def notify_new_followers
        new_follower_ids = (followers || []) - (previous_followers || [])
        new_follower_ids.each do |follower_id|
        follower = User.find_by(id: follower_id)
        next unless follower

        # Send a notification using Noticed
        FollowNotifier.with(follower: follower, followed_user: self).deliver_later(self)
        end
    end


end

