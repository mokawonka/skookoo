class RenameTypeInDocuments < ActiveRecord::Migration[7.0]
  def change
    rename_column :documents, :type, :nature
  end
end