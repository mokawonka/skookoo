class RepliesController < ApplicationController

    skip_before_action :verify_authenticity_token
    before_action :authorize_user!
    # before_action :check_timestamp, only: [:create, :update, :update_score , :edit, :destroy]
  
  
    def index
  
    end
  

    def new
      @reply = Reply.new
    end
  
    
    def create

        @reply = Reply.new(reply_params)
        @reply.userid = session[:user_id]
        @reply.score += 1
  
        @replytype = "parent" # default
        if @reply.recipientid != nil
          @replytype = "child"
        end

        respond_to do |format|
  
          if @reply.save
              format.js
              flash.now[:notice] = "Reply added successfully"
              current_user.votes[@reply.id] = "1"
              current_user.save
          else
              format.js
              flash.now[:notice] = ""
              @reply.errors.full_messages.each do |message|
                  flash.now[:notice] =  flash.now[:notice] + ' - ' + message
              end
          end
  
        end
  
    end


    def show

      @reply = Reply.find(params[:id])

      respond_to do |format|
        format.js
      end

    end


    def edit
      @reply = Reply.find(params[:id])

      respond_to do |format|
        format.js
      end

    end


    def update

      @reply = Reply.find(params[:id])
      @reply.edited = true

      respond_to do |format|
  
          if @reply.update(reply_params)
              format.js
              flash.now[:notice] = "comment edited"
          else
              format.js
              flash.now[:notice] = ""
              @reply.errors.full_messages.each do |message|
                  flash.now[:notice] =  flash.now[:notice] + ' - ' + message
              end 
          end

      end

    end


    def update_score

      @reply = Reply.find(params[:id])
  
      params[:reply].each do |increment, value|
        @reply.score += value.to_i
      end
  
      respond_to do |format|
    
        if @reply.update(reply_params)
            format.js
        end
  
      end
  
    end

    
  
    def destroy

        @reply = Reply.find(params[:id])

        @reply.deleted = true
        # recursively soft-deleting children too
        deletechildren(@reply)

        respond_to do |format|

          if @reply.save
            format.js
            flash.now[:notice] = "Reply deleted successfully"
          else

            @reply.errors.full_messages.each do |message|
              flash.now[:notice] =  flash.now[:notice] + ' - ' + message
            end 
          end

        end

    end
  
  
    private
  
    def reply_params
        params.require(:reply).permit(:userid, :highlightid, :content, :edited, :recipientid, :score, :deleted)
    end

    def deletechildren(reply)

      Reply.where(:recipientid => reply.id).each do |elem|
        elem.deleted = true
        elem.save
        deletechildren(elem)
      end

    end
  
  end
  