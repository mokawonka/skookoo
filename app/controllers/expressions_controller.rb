class ExpressionsController < ApplicationController
  skip_before_action :verify_authenticity_token  
  skip_before_action :require_user, if: -> { params[:token].present? }  # Add this to skip session auth for token

  def index
    user = current_user
    if user.blank?
      redirect_to login_path
      return
    end

    @expressions = Expression.where(userid: user.id)
    @pagy, @records = pagy(@expressions, items: 7)
  end



  def new
    @expression = Expression.new
  end



  def create
    token = params[:token].presence
    user = token.present? ? user_from_token(token) : current_user

    if user.blank?
      respond_to do |format|
        format.json { render json: { error: "Authentication required" }, status: :unauthorized }
        format.js   { render js: "alert('Please log in.');" }
        format.html { redirect_to login_path }
      end
      return
    end

    @expression = Expression.new(expression_params)
    @expression.userid = user.id

    respond_to do |format|
      if @expression.save
        flash.now[:notice] = "Added to Vocabulary" 

        if token.present?
          format.json { render json: { success: true, message: "Added to Vocabulary" } }  # web
        else
          format.json { render json: { success: true, message: "Added to Vocabulary" } }  # dictionary popup
          format.js                                                                       # document
          format.html { redirect_to expressions_path, notice: "Added to Vocabulary" }
        end
      else
        flash.now[:alert] = @expression.errors.full_messages.join(", ")
        format.json { render json: { error: flash.now[:alert] }, status: :unprocessable_entity }
        format.js   { render js: "alert('Failed: #{j flash.now[:alert]}');" }
        format.html { redirect_to expressions_path, alert: flash.now[:alert] }
      end
    end
  end


  
  def destroy
    @expression = Expression.find(params[:id])
    if @expression.userid != current_user.id
      flash.now[:alert] = "Unauthorized"
      redirect_to expressions_path
      return
    end

    @expression.destroy!
    flash.now[:notice] = "Expression deleted successfully"
    redirect_to expressions_path
  end

  private

  def expression_params
    params.require(:expression).permit(:userid, :docid, :cfi, :content, :definition, :origin)
  end
end