class EpubCreator
  include ActiveModel::Model

  attr_accessor :file, :user_id, :epub, :document

  validates :file, presence: true

  def call
    filename = file.is_a?(Pathname) ? file.to_s : file

    # Basic validation - must be .epub file
    unless filename.end_with?('.epub')
      errors.add(:file, "Must be an .epub file")
      return false
    end

    # 1. Try to parse the EPUB file
    begin
      reader = EPUB::Parser.parse(filename)
    rescue StandardError => e
      errors.add(:base, "Invalid or corrupted EPUB file: #{e.message}")
      return false
    end

    # 2. Create Epub record with metadata
    @epub = Epub.new(
      title:         reader.metadata.title,
      authors:       reader.metadata.creators&.first&.to_s&.split(";")&.join(", ") || "",
      lang:          reader.metadata.languages&.first&.content,
      sha3:          SHA3::Digest.file(filename).hexdigest,
      public_domain: false
    )

    # 3. SAVE THE RECORD FIRST – crucial for Active Storage attachments
    unless @epub.save
      errors.add(:epub, @epub.errors.full_messages.to_sentence)
      return false
    end

    # === ATTACH THE EPUB FILE ===
      if File.exist?(filename)
        Rails.logger.info "Attaching epub_file from: #{filename}"
        @epub.epub_file.attach(
          io:           File.open(filename),
          filename:     File.basename(filename),
          content_type: "application/epub+zip"
        )
        Rails.logger.info "Attach called. Now attached? #{@epub.epub_file.attached?}"
      else
        Rails.logger.info "File not found - cannot attach!"
        errors.add(:file, "Sample EPUB not found on disk")
        return false
      end

    # 4. Extract and attach cover image (only possible after record is saved)
    if reader.cover_image
      temp_dir = File.join(Dir.tmpdir, "ebook_#{$$}")

      begin
        Zip::File.open(filename) do |zip|
          zip.each do |entry|
            if File.basename(entry.name) == File.basename(reader.cover_image.href)
              temp_path = File.join(temp_dir, entry.name)

              FileUtils.mkdir_p(File.dirname(temp_path))
              zip.extract(entry, temp_path) { true }

              # Attach using the correct association name: cover_pic
              @epub.cover_pic.attach(
                io:           File.open(temp_path),
                filename:     File.basename(entry.name),
                content_type: Marcel::MimeType.for(Pathname.new(temp_path))
              )

              break  # No need to continue looking
            end
          end
        end
      ensure
        # Always clean up temporary files
        FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
      end
    end

    # Optional: save again if cover was attached and something changed
    @epub.save if @epub.cover_pic.attached? && @epub.changed?

    # 5. Create associated Document
    @document = Document.new(
      userid:  user_id,           # ← use the passed user_id (not session!)
      epubid:  @epub.id,
      title:   @epub.title,
      authors: @epub.authors,
      ispublic: @epub.public_domain
    )

    if @document.save
      true   # Success!
    else
      errors.add(:document, @document.errors.full_messages.to_sentence)
      false
    end
  end
end