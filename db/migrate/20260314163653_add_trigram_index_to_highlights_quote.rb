class AddTrigramIndexToHighlightsQuote < ActiveRecord::Migration[7.2]
  def up
    add_index :highlights, :quote,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_highlights_on_quote_trigram"
  end

  def down
    remove_index :highlights, name: "index_highlights_on_quote_trigram"
  end
end