class ExtensionsController < ApplicationController

  def modal
    @quote = params[:quote]
    render layout: false
  end

end