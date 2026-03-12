
class Expression < ApplicationRecord

    validates :userid, presence: true
    validates :origin, presence: true

    validates :content, presence: true, :length => { :minimum => 1, :message => "cannot be empty"}
    validates :definition, presence: true

end
