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


    validates :comment, presence:true, if: Proc.new { |a| !a.comment.nil? }

    
    include PgSearch::Model
    pg_search_scope :global_search,
        against: [:quote, :fromauthors, :fromtitle, :comment],
    using: {
        tsearch: { prefix: true }
    }

    
end
