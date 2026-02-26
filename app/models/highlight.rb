class Highlight < ApplicationRecord
    # belongs_to :document
    after_create_commit :generate_og_image
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

    # Ensure only one reaction type is set: comment, liked, emojiid, or gifid
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

      if reactions.length > 1
        errors.add(:base, "Only one reaction type allowed: comment, liked, emojiid, or gifid. Found: #{reactions.join(', ')}")
      end
    end

    include PgSearch::Model
    pg_search_scope :global_search,
        against: [:quote, :fromauthors, :fromtitle, :comment],
    using: {
        tsearch: { prefix: true }
    }

  private

  def generate_og_image
    GenerateOgImageJob.perform_later(self)
  end

  def soft_delete_replies
    Reply.where(highlightid: id).update_all(deleted: true)
  end

    
end
