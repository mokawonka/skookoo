class Epub < ApplicationRecord
    has_one_attached :epub_file

    has_one_attached :cover_pic


    attribute :public_domain, :boolean, default: true


    include PgSearch::Model
    pg_search_scope :global_search,
        against: [:title, :authors],
    using: {
        tsearch: { prefix: true }
    }

    def cover_url

        return false unless cover_pic.attached?

        Rails.application.routes.url_helpers.url_for(
            cover_pic.variant(resize_to_limit: [400, 400])
        )

    end
    
    def filename
        epub_file.filename.to_s if epub_file.attached?
    end

    
    def cover=(path_to_img)

      # saving image jpg/png to db 
      extension = File.extname(path_to_img).downcase

      cover_pic.attach(
        io: File.open(path_to_img),
        filename: 'cover_picture',
        content_type: extension == '.png' ? 'image/png' : 'image/jpeg'
      )

    end


    # static method used for seeding DB
    def self.save_epub(filepath, language)
        e = Epub.new

        e.epub_file.attach(
            io: File.open(filepath),
            filename: File.basename(filepath),
            content_type: "application/epub+zip"
        )

        e.save!

        begin
            e.epub_file.blob.open do |temp_epub|
            reader = EPUB::Parser.parse(temp_epub.path)

            e.title   = reader.metadata.title
            e.authors = reader.metadata.creators[0].to_s.split(";").join(", ")
            e.lang    = language
            e.sha3    = SHA3::Digest.file(filepath).hexdigest

            # extract cover
            if reader.cover_image
                extract_cover_from_epub(
                temp_epub.path,
                reader.cover_image.href,
                e
                )
            end
            end

            e.save!
            true

        rescue => e
            puts "Invalid epub file: #{e.message}"
            e.destroy!
            false
        end
    end

    def self.extract_cover_from_epub(epub_path, cover_href, epub_record)
        temp_dir = Dir.mktmpdir("ebook")

        Zip::File.open(epub_path) do |zipfile|
            zipfile.each do |entry|
            if File.basename(entry.name) == File.basename(cover_href)
                extracted_path = File.join(temp_dir, entry.name)
                FileUtils.mkdir_p(File.dirname(extracted_path))
                zipfile.extract(entry, extracted_path)

                epub_record.cover = extracted_path
                break
            end
            end
        end
    ensure
        FileUtils.rm_rf(temp_dir)
    end

end
