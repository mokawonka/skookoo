class User < ApplicationRecord


    has_many :notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"

    has_one_attached :avatar
    has_secure_password

    attribute :mana, :integer, default: 1
    attribute :darkmode, :boolean, default: false
    attribute :allownotifications, :boolean, default: true
    attribute :emailnotifications, :boolean, default: true  
    attribute :font, :string, default: 'League Spartan Bold'


    serialize :votes,     type: Hash
    serialize :following, type: Array
    serialize :followers, type: Array


    validates :email, email: true, presence: true, uniqueness: {message: "already taken"}
    
    validates :username, presence: true, uniqueness: {message: "already taken"}, :length => {:minimum => 2, :message => "must contain at least 2 characters"}
    
    validates :password, presence: true, :length => {:minimum => 3, :message => "length must be at least 3"}, :if => :password
    validates :password, confirmation: { case_sensitive: true }, :if => :password



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


end

