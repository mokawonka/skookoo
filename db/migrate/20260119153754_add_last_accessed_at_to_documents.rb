class AddLastAccessedAtToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :last_accessed_at, :datetime
    add_index :documents, :last_accessed_at   # very useful for sorting!
  end
end
