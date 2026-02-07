class Document < ApplicationRecord
    # belongs_to :user
    # has_many :highlights
    belongs_to :epub, optional: true, foreign_key: :epubid

    attribute :ispublic, :boolean, default: true
    attribute :progress, :decimal, default: 0.00000000
    attribute :opened, :integer, default: 0

    validates :epubid, presence: true
    validates :userid, presence: true

end
