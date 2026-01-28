# run with: rails r "load 'db/french.rb'"

@general_path = Rails.root.join("..", "free_french_epubs").to_s.freeze # /home/djeb/skookoo/../free_french_epubs
@test_epubs = Dir[File.join(@general_path, "**", "*.epub")]


failed = 0
@test_epubs.each_with_index do |file, index|
    puts "Test Dataset - Saving epub [#{File.basename(file)}] to database... [#{index+1} / #{@test_epubs.count}]"
    if !Epub.save_epub(file, "fr")
        failed += 1
    end
end
puts "Couldnt read #{failed} / #{@test_epubs.count} epubs."
