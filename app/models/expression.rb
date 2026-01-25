class Expression < ApplicationRecord

    validates :userid, presence: true
    validates :content, presence: true, :length => { :minimum => 1, :message => "cannot be empty"}

end
class Expression < ApplicationRecord

    validates :userid, presence: true
    validates :cfi, presence: true
    validates :content, presence: true, :length => { :minimum => 1, :message => "cannot be empty"}

end
