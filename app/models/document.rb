class Document < ApplicationRecord
  belongs_to :epub, optional: true, foreign_key: :epubid
  has_many :bookmarks, dependent: :destroy


  attribute :ispublic, :boolean, default: true
  attribute :progress, :decimal, default: 0.00000000
  attribute :opened, :integer, default: 0

  validates :epubid, presence: true
  validates :userid, presence: true

  after_create :notify_followers

  private

  def notify_followers
    return unless ispublic? && user_created?

    author = User.find_by(id: userid)
    return unless author

    followers = User.where(id: author.followers || [])
    return if followers.empty?

    WritingNotifier.with(author: author, document: self).deliver_later(followers)
  end
  
end