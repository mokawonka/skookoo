class DictionaryController < ApplicationController

  skip_before_action :verify_authenticity_token
  skip_before_action :require_user

  def lookup
    word = params[:word].to_s.strip.downcase.gsub(/[^a-z\-']/, "")

    return render json: { error: "No word provided" }, status: :bad_request if word.blank?

    result = DictionaryService.lookup(word)

    if result
      render json: result
    else
      render json: { error: "Word not found" }, status: :not_found
    end
  end

end