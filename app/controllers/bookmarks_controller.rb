class BookmarksController < ApplicationController

  before_action :set_document

  def create
    @bookmark = @document.bookmarks.create!(bookmark_params)
    render json: @bookmark
  end

  def destroy
    @document.bookmarks.find(params[:id]).destroy
    head :no_content
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def bookmark_params
    params.require(:bookmark).permit(:cfi, :percentage, :label)
  end

end