class AddSettingsToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :font_size, :integer, default: 18
    add_column :documents, :line_height, :float, default: 1.6
    add_column :documents, :bg_color, :string, default: "#ffffff"
    add_column :documents, :text_color, :string, default: "#111111"
  end
end
