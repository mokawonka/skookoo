class Highlight < ApplicationRecord
    # belongs_to :document

    has_rich_text :comment

    attribute :score, :integer, default: 0


    validates :userid, presence: true
    validates :docid, presence: true
    validates :quote, presence: true, :length => { :minimum => 20, :message => "must contain at least 20 characters"}
    validates :cfi, presence: true
    validates :fromauthors, presence: true
    validates :fromtitle, presence: true

    # Ensure only one reaction type is set: comment, liked, emojiid, or gifid
    validate :only_one_reaction_type

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

    
end
