class UsersController < ApplicationController
    protect_from_forgery
    skip_before_action :require_user, only: [:new, :create, :show] 

    before_action :authorize_user!, only: [:show_followers, :show_following, :show_replies, :follow, :unfollow, 
                                           :update_data, :update_profile, :update_votes, :switch_mode, :update_font, 
                                           :plusonemana, :minusonemana, :plustwomana, :minustwomana]
    
    # 3 seconds delay on user post requests to prevent attacks
    # before_action :check_timestamp, only: [ :create, :follow, :unfollow, 
    #                                        :update_data, :update_profile, :update_votes,
    #                                        :switch_mode, :update_font, 
    #                                        :plusonemana, :minusonemana, :plustwomana, :minustwomana]


    def new
        if !logged_in?
            @user = User.new
        else
            redirect_to mysettings_path
        end
    end


    def create
        @user = User.new(user_params)

        @user.name = @user.username

        if @user.save

            # creating a sample epub
            service = EpubCreator.new(
                file:    Rails.root.join("app", "assets", "samples", "demo.epub"), 
                user_id: @user.id
            )

            if service.call
                session[:user_id] = @user.id
                redirect_to documents_path, notice: "Welcome! Your account is ready."
            end

        else
            flash[:alert] = @user.errors.full_messages.join(" • ") if @user.errors.any?
            redirect_to signup_path
        end

    end


    def show
        @user = User.find_by_username(params[:username])
        
        if @user.hooked != nil
            @hookedhighlight = Highlight.find_by_id(@user.hooked)
        end

        @totalH = Highlight.where(:userid => @user.id).count
        @totalR = Reply.where(:deleted => false).where(:userid => @user.id).count

        @pagy, @hrecords = pagy(Highlight.where(:userid => @user.id), items: 7)
        render "highlights/_scrollable_list" if params[:page]
    end


    def edit
        if !logged_in?
            redirect_to root_path
        else
            myuserid = session[:user_id]
            @user = User.find(myuserid)
            
            render :edit
        end
    end


    def update
        @user = User.find(params[:id])

        if @user.update(user_params)
            flash.now[:notice] = "Changes saved"
            render :edit
        else
            flash.now[:alert] = ""
            @user.errors.full_messages.each do |message|
                flash.now[:alert] =  flash.now[:alert] + ' - ' + message
            end

            render :edit
        end
    end


    def update_data
        @user = User.find(params[:id])

        respond_to do |format|

            if @user.update(user_params)
                flash.now[:notice] = "Changes saved"
                format.js
            else
                flash.now[:alert] = ""
                @user.errors.full_messages.each do |message|
                    flash.now[:alert] =  flash.now[:alert] + ' - ' + message
                end
                format.js
            end
        end

    end


    def update_profile
        @user = User.find(params[:id])

        respond_to do |format|

            if @user.update(user_params)
                flash.now[:notice] = "Changes saved"
                format.js
            else
                flash.now[:alert] = ""
                @user.errors.full_messages.each do |message|
                    flash.now[:alert] =  flash.now[:alert] + ' - ' + message
                end

                format.js
            end
        end

    end


    def update_votes
        
        @user = User.find(params[:id])
        
        # deleting passwords, otherwise it wont update
        if params[:password].blank?
            params.delete(:password)
            params.delete(:password_confirmation)
        end

        params[:user].each do |thekey, thevalue|

            #get previous vote if present
            @thevote = @user.getvote(thekey)
            @thekey = thekey
            @thevalue = thevalue

            if @thevote == 1 # already upvoted

                if thevalue == "1"
                    @user.votes.delete(thekey)
                elsif thevalue == "-1"
                    @user.votes[thekey] = thevalue
                end

            elsif @thevote == -1 # already downvoted

                if thevalue == "-1"
                    @user.votes.delete(thekey)
                elsif thevalue == "1"
                    @user.votes[thekey] = thevalue
                end

            else # 0 / not present
                @user.votes.store(thekey, thevalue)
            end

        end

        respond_to do |format|
  
            if @user.update(user_params)
                format.js 
            else
                format.js
            end
    
        end
        
    end

    
    def update_font
       
        @user = User.find(params[:id])
        @user.font = params[:font]

        respond_to do |format|
            if @user.save
                format.js {render inline: "location.reload();"}
            end
        end
    end


    def update_hooked
       
        @user = User.find(params[:id])
        
        @user.hooked = params[:user][:hooked]

        respond_to do |format|

            if @user.save
                format.js {render inline: "$('#hook-<%=@user.hooked%>').text('hooked'); $('.hookedhighlight').hide();"}
            end

        end
    end

    def plusonemana
        @user = User.find(params[:id])
        @user.mana += 1
        respond_to do |format|
            if @user.save
                format.js
            end
        end
    end

    def minusonemana
        @user = User.find(params[:id])
        @user.mana -= 1
        respond_to do |format|
            if @user.save
                format.js
            end
        end
    end

    def plustwomana
        @user = User.find(params[:id])
        @user.mana += 2
        respond_to do |format|
            if @user.save
                format.js
            end
        end
    end

    def minustwomana
        @user = User.find(params[:id])
        @user.mana -= 2
        respond_to do |format|
            if @user.save
                format.js
            end
        end
    end


    def switch_mode
        @user = User.find(params[:id])
        
        if @user.darkmode
            @user.darkmode = false
        else
            @user.darkmode = true
        end

        respond_to do |format|
            if @user.save
                format.js {render inline: "location.reload();" }
            end
        end

    end


    def follow

        @user = User.find(params[:id])

        if !@user.followers.include?current_user.id 
            @user.followers.append(current_user.id)
        end

        if !current_user.following.include?@user.id 
            current_user.following.append(@user.id)
        end

        respond_to do |format|
            if current_user.save
                if @user.save
                    format.js
                end
            end
        end

    end

    def unfollow

        if logged_in?
            @user = User.find(params[:id])

            if @user.followers.include?current_user.id 
                @user.followers.delete(current_user.id)
            end

            if current_user.following.include?@user.id 
                current_user.following.delete(@user.id)
            end

            respond_to do |format|
                if current_user.save
                    if @user.save
                        format.js
                    end
                end
            end
        end

    end


    def show_replies
        @user = User.find(params[:id])
        @pagy, @rrecords = pagy(Reply.where(:userid => @user.id).where(:deleted => false), items: 7)
        render "replies/_scrollable_list" if params[:page]
    end


    def show_following

        @user = User.find(params[:id])

        @following = []
        @user.following.each do |u|
            @following.append(u)
        end

        respond_to do |format|
            format.js
        end
    end

    def show_followers

        @user = User.find(params[:id])

        @followers = []
        @user.followers.each do |u|
            @followers.append(u)
        end

        respond_to do |format|
            format.js
        end
    end



    def destroy

        Reply.where(:userid => session[:user_id]).each do |mr|
            mr.deleted = true
            mr.save
        end
        Highlight.where(:userid => session[:user_id]).each do |h|
            # soft-deleting all highlight replies written by other users
            Reply.where(:highlightid => h.id).each do |r|
                r.deleted = true
                r.save
            end
        end
        
        Highlight.where(:userid => session[:user_id]).delete_all
        Document.where(:userid => session[:user_id]).delete_all
        Idea.where(:userid => session[:user_id]).delete_all
        Expression.where(:userid => session[:user_id]).delete_all


        User.find(session[:user_id]).destroy
        session[:user_id] = nil   
        flash.now[:notice] = "Account deleted"  
        redirect_to root_path
    end



    private

        def user_params
            params.require(:user).permit(:email, :name, :username, :password, :password_confirmation, 
                                         :avatar, :mana, :votes, :darkmode, :font, 
                                         :allownotifications, :emailnotifications, 
                                         :hooked, :following, :followers, :bio, :location)
        end

end