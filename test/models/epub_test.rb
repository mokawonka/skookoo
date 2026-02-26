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
    # Skip this test as it requires file system mocking
    skip "File system mocking requires Mocha"
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
    skip "EPUB parsing mocking requires Mocha"
  end

  test "save_epub should handle invalid epub files" do
    # Skip this test as it requires mocking
    skip "EPUB error handling mocking requires Mocha"
  end

  test "extract_cover_from_epub should extract cover image" do
    epub_record = Epub.create!(title: "Test", authors: "Author", lang: "en")
    
    # Skip this test as it requires Zip file mocking
    skip "Zip file mocking requires Mocha"
  end

  test "extract_cover_from_epub should cleanup temp directory" do
    epub_record = Epub.create!(title: "Test", authors: "Author", lang: "en")
    
    # Skip this test as it requires directory mocking
    skip "Directory mocking requires Mocha"
  end
end
