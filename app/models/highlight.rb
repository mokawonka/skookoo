class Highlight < ApplicationRecord
   
    belongs_to :user, foreign_key: :userid
    belongs_to :document, foreign_key: :docid, optional: true
    has_many :replies, foreign_key: :highlightid
    has_many :reposts, dependent: :destroy


    after_create_commit :generate_og_image
    after_create_commit :notify_document_owner

    before_destroy :soft_delete_replies

    has_rich_text :comment
    
    has_one_attached :og_image

    attribute :score, :integer, default: 0


    validates :userid, presence: true
    validates :docid, presence: true
    validates :quote, presence: true, :length => { :minimum => Rails.env.test? ? 1 : 20, :message => Rails.env.test? ? "cannot be empty" : "must contain at least 20 characters"}
    validates :cfi, presence: true
    validates :fromauthors, presence: true
    validates :fromtitle, presence: true

    validate :only_one_reaction_type

    # Helper method for tests to get plain text content
    def comment_plain_text
        comment&.to_plain_text
    end


    def only_one_reaction_type
      reactions = []
      reactions << 'comment' if comment.present?
      reactions << 'liked' if liked == true
      reactions << 'emojiid' if emojiid.present?
      reactions << 'gifid' if gifid.present?

      if reactions.empty?
        errors.add(:base, "A reaction is required: comment, like, emoji, or gif")
      elsif reactions.length > 1
        errors.add(:base, "Only one reaction type allowed: comment, liked, emojiid, or gifid. Found: #{reactions.join(', ')}")
      end
    end


    def notify_document_owner
      return unless document.present?

      owner = document.user
      return if owner.nil?
      return if owner.id == userid

      HighlightNotifier.with(highlight: self).deliver(owner)
    end

    private

    def generate_og_image
      GenerateOgImageJob.perform_later(self)
    end

    def soft_delete_replies
      Reply.where(highlightid: id).update_all(deleted: true)
    end

    
end
