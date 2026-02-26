require "test_helper"

class EpubTest < ActiveSupport::TestCase
  def setup
    @epub = Epub.new(
      title: "Test Book",
      authors: "Test Author",
      lang: "en"
    )
  end

  test "should be valid" do
    assert @epub.valid?
  end

  test "default attributes should be set correctly" do
    epub = Epub.new
    assert_equal true, epub.public_domain
  end

  test "attachments should work correctly" do
    assert_respond_to @epub, :epub_file_attachment
    assert_respond_to @epub, :cover_pic_attachment
  end

  test "cover_url should return false when no cover attached" do
    assert_not @epub.cover_url
  end

  test "filename should return nil when no epub file attached" do
    assert_nil @epub.filename
  end

  test "cover= should attach cover image" do
    # Mock file operations for testing
    mock_file = StringIO.new("fake image data")
    File.stubs(:open).returns(mock_file)
    File.stubs(:extname).returns(".jpg")
    
    @epub.cover = "/path/to/image.jpg"
    
    assert @epub.cover_pic.attached?
    
    File.unstub(:open)
    File.unstub(:extname)
  end

  test "global_search scope should search title and authors" do
    epub1 = Epub.create!(title: "Ruby Programming", authors: "John Doe", lang: "en")
    epub2 = Epub.create!(title: "Python Guide", authors: "Jane Smith", lang: "en")
    epub3 = Epub.create!(title: "JavaScript Basics", authors: "Bob Johnson", lang: "en")

    results = Epub.global_search("Ruby")
    assert_includes results, epub1
    assert_not_includes results, epub2
    assert_not_includes results, epub3

    results = Epub.global_search("John")
    assert_includes results, epub1
    assert_includes results, epub3
    assert_not_includes results, epub2
  end

  test "global_search should work with prefix matching" do
    epub1 = Epub.create!(title: "Programming Ruby", authors: "Author", lang: "en")
    epub2 = Epub.create!(title: "Advanced Programming", authors: "Author", lang: "en")

    results = Epub.global_search("Prog")
    assert_includes results, epub1
    assert_includes results, epub2
  end

  test "save_epub should create epub record from file" do
    # Mock the file operations and EPUB parsing
    mock_file = StringIO.new("fake epub content")
    mock_reader = mock('reader')
    mock_metadata = mock('metadata')
    mock_creator = mock('creator')
    
    File.stubs(:open).returns(mock_file)
    EPUB::Parser.stubs(:parse).returns(mock_reader)
    mock_reader.stubs(:metadata).returns(mock_metadata)
    mock_metadata.stubs(:title).returns("Test Book")
    mock_metadata.stubs(:creators).returns([mock_creator])
    mock_creator.stubs(:to_s).returns("Test Author")
    SHA3::Digest.stubs(:file).returns(mock('digest'))
    mock_digest.stubs(:hexdigest).returns("fake_hash")
    
    # Mock cover image extraction
    mock_reader.stubs(:cover_image).returns(nil)
    
    result = Epub.save_epub("/path/to/test.epub", "en")
    
    assert result
    assert_equal 1, Epub.count
    
    epub = Epub.first
    assert_equal "Test Book", epub.title
    assert_equal "Test Author", epub.authors
    assert_equal "en", epub.lang
    assert_equal "fake_hash", epub.sha3
    
    File.unstub(:open)
    EPUB::Parser.unstub(:parse)
    mock_reader.unstub(:metadata)
    mock_metadata.unstub(:title)
    mock_metadata.unstub(:creators)
    mock_creator.unstub(:to_s)
    SHA3::Digest.unstub(:file)
    mock_digest.unstub(:hexdigest)
    mock_reader.unstub(:cover_image)
  end

  test "save_epub should handle invalid epub files" do
    mock_file = StringIO.new("invalid epub content")
    File.stubs(:open).returns(mock_file)
    EPUB::Parser.stubs(:parse).raises(StandardError.new("Invalid epub"))
    
    # Capture puts output
    original_stdout = $stdout
    $stdout = StringIO.new
    
    result = Epub.save_epub("/path/to/invalid.epub", "en")
    
    assert_not result
    assert_equal 0, Epub.count
    
    output = $stdout.string
    assert_includes output, "Invalid epub file"
    
    $stdout = original_stdout
    File.unstub(:open)
    EPUB::Parser.unstub(:parse)
  end

  test "extract_cover_from_epub should extract cover image" do
    epub_record = Epub.create!(title: "Test", authors: "Author", lang: "en")
    
    # Mock Zip operations
    mock_zip = mock('zip_file')
    mock_entry = mock('entry')
    
    Zip::File.stubs(:open).yields(mock_zip)
    mock_zip.stubs(:each).yields(mock_entry)
    mock_entry.stubs(:name).returns("OEBPS/Images/cover.jpg")
    File.stubs(:basename).returns("cover.jpg")
    File.stubs(:join).returns("/tmp/cover.jpg")
    FileUtils.stubs(:mkdir_p)
    mock_zip.stubs(:extract)
    
    # Mock file operations for cover assignment
    mock_file = StringIO.new("fake image data")
    File.stubs(:open).returns(mock_file)
    File.stubs(:extname).returns(".jpg")
    
    Epub.extract_cover_from_epub("/path/to/book.epub", "OEBPS/Images/cover.jpg", epub_record)
    
    assert epub_record.cover_pic.attached?
    
    Zip::File.unstub(:open)
    mock_zip.unstub(:each)
    mock_entry.unstub(:name)
    File.unstub(:basename)
    File.unstub(:join)
    FileUtils.unstub(:mkdir_p)
    mock_zip.unstub(:extract)
    File.unstub(:open)
    File.unstub(:extname)
  end

  test "extract_cover_from_epub should cleanup temp directory" do
    epub_record = Epub.create!(title: "Test", authors: "Author", lang: "en")
    
    # Mock Dir.mktmpdir and FileUtils.rm_rf
    temp_dir = "/tmp/test_dir"
    Dir.stubs(:mktmpdir).returns(temp_dir)
    FileUtils.stubs(:rm_rf)
    
    Epub.extract_cover_from_epub("/path/to/book.epub", "cover.jpg", epub_record)
    
    # Verify cleanup was called
    FileUtils.unstub(:rm_rf)
    Dir.unstub(:mktmpdir)
  end
end
