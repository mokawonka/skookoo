class ExpressionsController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authorize_user!
  
  
    def index
        myuserid = session[:user_id]

        #retrieving all expressions owned by user
        @expressions = Expression.where(:userid => myuserid)
        @pagy, @records = pagy(@expressions, items: 7)

    end
  
    def new
      @expression = Expression.new
    end
  
    def create

        @expression = Expression.new(expression_params)
        @expression.userid = session[:user_id]
  
        respond_to do |format|
  
          if @expression.save
              format.js
              flash.now[:notice] = "Added to Vocabulary"
          else

            format.js
            flash.now[:notice] = ""
            @expression.errors.full_messages.each do |message|
                flash.now[:notice] =  flash.now[:notice] + ' - ' + message
            end
    
          end
  
        end
  
    end
  
  
    def destroy
      Expression.find(params[:id]).destroy!
      flash.now[:notice] = "Expression deleted successfully"
      redirect_to expressions_path
    end
  
  
    private
  
    def expression_params
        params.require(:expression).permit(:userid, :docid, :cfi, :content, :definition)
    end
  
  end
  