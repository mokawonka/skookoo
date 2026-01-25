class Epub < ApplicationRecord
    has_one_attached :epub_file
    has_one_attached :cover_pic


    attribute :public_domain, :boolean, default: true

    def cover_url

        return "https://via.placeholder.com/260x360?text=#{title.to_s.truncate(20)}" unless cover_pic.attached?

        Rails.application.routes.url_helpers.rails_blob_url(
            cover_pic,
            host: Rails.application.config.action_mailer.default_url_options&.[](:host) || "http://localhost:3000"
        )
    end
    
    def filename
        epub_file.filename.to_s if epub_file.attached?
    end

    def epub_on_disk

        if epub_file.attached? && (epub_file.content_type.in?(%w(application/epub+zip)) || epub_file.content_type.in?(%w(application/zip)) )
          ActiveStorage::Blob.service.path_for(epub_file.key)
        else
          return -1
        end
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
    def self.save_epub(filepath)

      e = Epub.new
      e.epub_file.attach(io: File.open(filepath), 
                          filename: File.basename(filepath),
                          content_type: "application/epub+zip") 
      e.save
  
      filename = e.epub_on_disk
  
      begin
          reader = EPUB::Parser.parse(filename)
      rescue
          puts "Invalid epub file\n"
          e.destroy!
          return false
      else
      
          e.title = reader.metadata.title
          e.authors = reader.metadata.creators[0].to_s.split(";").join(", ")
          e.lang = reader.metadata.languages[0].content
          e.sha3 = SHA3::Digest.file(filepath).hexdigest
          # e.public_domain equals true by default 
      
          # get cover pic
          if reader.cover_image
      
              temp_dir = File.join(Dir.tmpdir, "ebook" + $$.to_s)
              Zip::File.open(filename) do |zipfile|
                  zipfile.each do |file|
      
                      if File.basename(file.to_s) == File.basename(reader.cover_image.href)
      
                          f_path = File.join(temp_dir, file.name)
                          FileUtils.mkdir_p(File.dirname(f_path))
                          zipfile.extract(file, f_path)
      
                          e.cover = f_path
      
                          #deleting tmp folder
                          FileUtils.rm_rf temp_dir
                      end
                  end
      
              end
          end
      
          e.save
          return true
  
      end
  
    end

end
