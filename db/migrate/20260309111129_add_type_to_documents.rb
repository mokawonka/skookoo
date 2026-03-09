class AddTypeToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :type, :string, default: "book"
  end
end