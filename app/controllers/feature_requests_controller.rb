class FeatureRequestsController < ApplicationController

  def new
    @feature_request = FeatureRequest.new
    respond_to do |format|
      format.html         # if full page
      format.turbo_stream # for modal
    end
  end



  def create
    @feature_request = FeatureRequest.new(feature_request_params)
    @feature_request.user = current_user if logged_in?

    if @feature_request.save
      # Optional: send email to admin, or notify via Slack/Discord
      # FeatureRequestMailer.with(request: @feature_request).new_request.deliver_later

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("feature_request_form", partial: "success") }
        format.html { redirect_to root_path, notice: "Thank you! Your feature request has been submitted." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("feature_request_form", partial: "form", locals: { feature_request: @feature_request }) }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end



  private

  def feature_request_params
    params.require(:feature_request).permit(:title, :description)
  end


end
