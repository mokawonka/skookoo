# app/services/dictionary_service.rb
class DictionaryService

  def self.lookup(word)
    lexicon = WordNet::Lexicon.new
    synsets = lexicon.lookup_synsets(word.downcase)
    return nil if synsets.empty?

    meanings = synsets.group_by(&:pos).map do |pos, sets|
      pos_label = case pos
        when "n"      then "noun"
        when "v"      then "verb"
        when "a", "s" then "adjective"
        when "r"      then "adverb"
        else pos.to_s
      end

      {
        partOfSpeech: pos_label,
        definitions:  sets.first(2).map { |s|
          {
            definition: s.definition,
            example: s.samples.first
          }
        },
        synonyms: begin
          sets.first.words
              .map(&:lemma)
              .map  { |w| w.gsub("_", " ") }
              .reject { |w| w.downcase == word.downcase }
              .first(6)
        rescue
          []
        end
      }
    end.first(2)

    { word: word, phonetic: nil, meanings: meanings }

  rescue => e
    Rails.logger.error("WordNet error for '#{word}': #{e.message}")
    nil
  end

end