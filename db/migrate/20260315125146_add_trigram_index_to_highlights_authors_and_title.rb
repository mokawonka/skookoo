class AddTrigramIndexToHighlightsAuthorsAndTitle < ActiveRecord::Migration[7.2]
  def up
    add_index :highlights, :fromauthors,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_highlights_on_fromauthors_trigram"

    add_index :highlights, :fromtitle,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_highlights_on_fromtitle_trigram"
  end

  def down
    remove_index :highlights, name: "index_highlights_on_fromauthors_trigram"
    remove_index :highlights, name: "index_highlights_on_fromtitle_trigram"
  end
end