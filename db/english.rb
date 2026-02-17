# run with: rails r "load 'db/english.rb'"

@general_path = Rails.root.join("..", "free_english_epubs").to_s.freeze
@test_epubs = Dir[File.join(@general_path, "**", "*.epub")]


skipped = 0
imported = 0
failed = 0

@test_epubs.each_with_index do |file, index|
  filename = File.basename(file)
  puts "[#{index+1}/#{@test_epubs.count}] Checking #{filename}..."

  # Compute hash once — fast and reliable
  file_hash = SHA3::Digest.file(file).hexdigest

  if Epub.exists?(sha3: file_hash)
    puts "  → Already exists in database (by sha3 hash) → skipped"
    skipped += 1
    next
  end

  puts "  → Importing new EPUB..."

  if Epub.save_epub(file, "en")
    imported += 1
    puts "  → Success!"
  else
    failed += 1
    puts "  → Failed"
  end
end

puts "\nSummary:"
puts "  Imported new: #{imported}"
puts "  Skipped (already exists): #{skipped}"
puts "  Failed: #{failed}"
puts "  Total files scanned: #{@test_epubs.count}"