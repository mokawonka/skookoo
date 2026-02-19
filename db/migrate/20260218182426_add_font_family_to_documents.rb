class AddFontFamilyToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :font_family, :string, default: 'Crimson Pro'
  end
end
