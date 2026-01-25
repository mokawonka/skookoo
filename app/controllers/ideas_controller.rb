class IdeasController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authorize_user!
  
  
    def index
        myuserid = session[:user_id]

        #retrieving all ideas owned by user
        @ideas = Idea.where(:userid => myuserid)
        @pagy, @records = pagy(@ideas, items: 7)

    end
  
    def new
      @idea = Idea.new
    end
  
    def create

        @idea = Idea.new(idea_params)
        @idea.userid = session[:user_id]
  
        respond_to do |format|
  
          if @idea.save
              format.js
              flash.now[:notice] = "Idea added successfully"
          else

            format.js
            flash.now[:notice] = ""
            @idea.errors.full_messages.each do |message|
                flash.now[:notice] =  flash.now[:notice] + ' - ' + message
            end
    
          end
  
        end
  
    end
  
  
    def destroy
      Idea.find(params[:id]).destroy!
      flash.now[:notice] = "idea deleted successfully"
      redirect_to ideas_path
    end
  
  
    private
  
    def idea_params
        params.require(:idea).permit(:userid, :docid, :cfi, :content)
    end
  
  end
  