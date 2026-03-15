class UserDataPdfService < Prawn::Document

  def initialize(user, highlights, replies)
    super(top_margin: 50)

    font_families.update(
        "LeagueSpartan" => {
            normal: Rails.root.join("app/assets/fonts/LeagueSpartan-Regular.ttf"),
            bold:   Rails.root.join("app/assets/fonts/LeagueSpartan-Bold.ttf")
        }
    )
    font "LeagueSpartan"

    @user = user
    @highlights = highlights
    @replies = replies

    preload_documents

    header
    highlights_section
    replies_section
    footer
  end


  def preload_documents
    doc_ids = @highlights.pluck(:docid).compact.uniq
    @documents = Document.where(id: doc_ids).index_by(&:id)
  end


  def header
    text "My Skookoo Data Export", size: 22, style: :bold
    move_down 10

    text "Username: #{@user.username}"
    text "Email: #{@user.email}"
    text "Exported at: #{Time.current.strftime('%B %d, %Y %H:%M')}"

    move_down 20
    stroke_horizontal_rule
    move_down 20
  end


  def highlights_section
    text "Highlights (#{@highlights.count})", size: 18, style: :bold
    move_down 15

    @highlights.each do |h|

      document = @documents[h.docid]
      title = document&.title || h.fromtitle || "Unknown Document"

      text title.to_s, style: :bold, size: 12
      text "Author: #{h.fromauthors}" if h.fromauthors.present?

      move_down 5

      text "Quote:", style: :bold
      indent(10) do
        text h.quote.to_s
      end

      move_down 5
      text "Created at: #{h.created_at.strftime('%B %d, %Y %H:%M')}"

      move_down 15
      stroke_horizontal_rule
      move_down 15
    end
  end


  def replies_section
    start_new_page

    text "Replies (#{@replies.count})", size: 18, style: :bold
    move_down 15

    @replies.each do |r|
      move_down 5

      indent(10) do
        plain_content = r.content.body.to_plain_text.squish
        text plain_content
      end

      move_down 5
      text "Created at: #{r.created_at.strftime('%B %d, %Y %H:%M')}"

      move_down 15
      stroke_horizontal_rule
      move_down 15
    end
  end


  def footer
    number_pages "<page> / <total>",
      at: [bounds.right - 50, 0],
      align: :right,
      size: 9
  end

end