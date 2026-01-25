class Reply < ApplicationRecord
    after_create_commit :notify_recipient

    has_rich_text :content
    attribute :edited, :boolean, default: false
    attribute :deleted, :boolean, default: false
    attribute :score, :integer, default: 0

    validates :userid, presence: true
    validates :highlightid, presence: true    
    validates :content, presence: true, :length => { :minimum => 1, :message => "cannot be empty"}


    def getsubreplies

        raw_subreplies = Reply.where(:highlightid => self.highlightid).where(:recipientid => self.id).where(:deleted => false)

        return raw_subreplies
    end


  private

  def notify_recipient
    # Find the parent highlight (adjust model name if not called Highlight)
    hightlight = Highlight.find_by(id: highlightid)

    return unless hightlight.present?

    # owner/author of the parent highlight
    highlightowner = User.find_by(id: hightlight.userid)

    # Skip if notifying yourself and if replying to a reply
    if highlightowner&.id != userid && !self.recipientid
        ReplyNotifier.with(reply: self).deliver_later(highlightowner)

    end

    # or .deliver(recipient) if you don't want background job yet

    # replying to a reply
    if self.recipientid
        parentreply = Reply.find_by(id: self.recipientid)
        parentreplyowner = User.find_by(id: parentreply.userid)

        if parentreply.userid != userid
            ReplyNotifier.with(reply: self).deliver_later(parentreplyowner)
        end
    end

end


end

