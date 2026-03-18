class UsersController < ApplicationController
    protect_from_forgery
    skip_before_action :require_user, only: [:new, :create, :show, :hovercard] 


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
            service = EpubCreatorService.new(
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

        if @user.nil?
            raise ActiveRecord::RecordNotFound
        end
                
        if @user.hooked.present?
            @hookedhighlight = Highlight.find_by_id(@user.hooked)
        end

        @avatar_filepath = "default-avatar.svg"
        if @user.avatar.attached?
            @avatar_filepath = @user.avatar.variant(resize_to_limit:[400, 400])
        end

        @background_filepath = "default-background.png"
        if @user.background.attached?
            @background_filepath = @user.background.variant(resize_to_limit:[1920, 1080])
        end

        @documents = Document.where(userid: @user.id, ispublic: true, user_created: true)

        @totalR = Reply.where(deleted: false).where(userid: @user.id).count
        @totalD = @documents.count

        highlights = Highlight.where(userid: @user.id)
        @totalH    = highlights.count
        highlights = highlights.where.not(id: @hookedhighlight.id) if @hookedhighlight.present?

        @pagy, @hrecords = pagy(highlights.order(created_at: :desc), items: 7)
        
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
            if request.xhr?
                render json: { status: :ok }
            else
                redirect_back fallback_location: user_path(@user), notice: "Changes saved"
            end
        else
            if request.xhr?
                render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
            else
                redirect_back fallback_location: user_path(@user), alert: @user.errors.full_messages.to_sentence
            end
        end
    end
    

    def update_votes
        @user = User.find(params[:id])
        entity_id = params[:entity_id]
        new_vote = params[:vote].to_s
        current_vote = @user.getvote(entity_id)

        if current_vote == 1
            if new_vote == "1"
            @user.votes.delete(entity_id)        # undo upvote
            elsif new_vote == "-1"
            @user.votes[entity_id] = new_vote    # switch to downvote
            end
        elsif current_vote == -1
            if new_vote == "-1"
            @user.votes.delete(entity_id)        # undo downvote
            elsif new_vote == "1"
            @user.votes[entity_id] = new_vote    # switch to upvote
            end
        else
            @user.votes.store(entity_id, new_vote) # fresh vote
        end

        @user.save
        render json: { vote: @user.getvote(entity_id) }
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

        # Prevent self-follow
        if current_user.id == @user.id
            head :ok and return
        end

        if @user.private?
            # === Private profile ===
            unless @user.pending_follow_requests.include?(current_user.id)
            @user.pending_follow_requests << current_user.id
            @user.save
            end

            # Optional notification (uncomment later)
            FollowRequestNotifier.with(follower: current_user, followed_user: @user).deliver_later(@user)

            flash.now[:notice] = "Follow request sent and is pending approval"

        else
            # === Public profile ===
            @user.followers << current_user.id unless @user.followers.include?(current_user.id)
            current_user.following << @user.id unless current_user.following.include?(@user.id)
            
            current_user.save
            @user.save

            flash.now[:notice] = "Following"
        end

        # ← This is the clean part
        respond_to do |format|
            format.js 
        end
    end


    def approve_follow_request
        @requester = User.find(params[:follower_id])
        @user = current_user 

        if @user.pending_follow_requests.include?(@requester.id)
            @user.pending_follow_requests.delete(@requester.id)

            # Accept the follow
            @user.followers << @requester.id unless @user.followers.include?(@requester.id)
            @requester.following << @user.id unless @requester.following.include?(@user.id)

            @user.save
            @requester.save

            flash.now[:notice] = "Follow request approved"

            FollowApprovedNotifier.with( follower: @requester, followed_user: @user).deliver_later(@requester)
        end

        # Reload the list for the modal
        @pending_requesters = User.where(id: @user.pending_follow_requests || [])

        respond_to do |format|
            format.js { render 'refresh_follow_requests' }
        end
    end


    def reject_follow_request
        @requester = User.find(params[:follower_id])
        @user = current_user

        if @user.pending_follow_requests.include?(@requester.id)
            @user.pending_follow_requests.delete(@requester.id)
            @user.save

            flash.now[:notice] = "Follow request rejected"
        end

        # Reload the list for the modal
        @pending_requesters = User.where(id: @user.pending_follow_requests || [])

        respond_to do |format|
            format.js { render 'refresh_follow_requests' }
        end
    end


    def show_follow_requests
        @user = User.find(params[:id]) 

        # Prevent nil error if the array is not initialized
        pending_ids = @user.pending_follow_requests || []

        @pending_requesters = User.where(id: pending_ids)

        respond_to do |format|
            format.js
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


    def hovercard
        unless request.xhr?
            redirect_to root_path and return
        end
        @user = User.find(params[:id])
        render partial: "users/hovercard", locals: { user: @user }
    end


    def mention_search
        q = params[:q].to_s.strip.downcase
        return render json: [] if q.length < 2 || q.length > 30

        users = User
            .where("LOWER(username) LIKE :q OR LOWER(name) LIKE :q", q: "#{q}%")
            .order(Arel.sql(<<~SQL))
            CASE
                WHEN LOWER(username) = '#{q}'     THEN 0
                WHEN LOWER(username) LIKE '#{q}%' THEN 1
                WHEN LOWER(name)     LIKE '#{q}%' THEN 2
                ELSE 3
            END
            SQL
            .limit(8)
            .select(:id, :username, :name)

        following_ids = Set.new(current_user.following || [])

        result = users.map do |u|
            avatar_url = u.avatar.attached? \
            ? url_for(u.avatar.variant(resize_to_limit: [44, 44])) \
            : helpers.asset_path("default-avatar.svg")

            {
            id:           u.id,
            username:     u.username,
            name:         u.name,
            avatar_url:   avatar_url,
            is_following: following_ids.include?(u.id.to_s) || following_ids.include?(u.id)
            }
        end

        expires_in 10.seconds, public: false
        respond_to do |format|
            format.json { render json: result }
        end
    end


    def download_data
        return head :forbidden unless current_user == User.find(params[:id])

        user = current_user

        highlights = Highlight.where(:userid => user.id)
        replies    = Reply.where(:userid => user.id)

        respond_to do |format|

            format.json do
            json_data = {
                user: {
                id: user.id,
                username: user.username,
                email: user.email
                },
                highlights: highlights.map do |h|
                {
                    highlight_id: h.id,
                    document_id: h.docid,
                    document_title: h.fromtitle,
                    document_author: h.fromauthors,
                    quote: h.quote,
                    cfi: h.cfi,
                    created_at: h.created_at
                }
                end,
                replies: replies.map do |r|
                {
                    reply_id: r.id,
                    highlight_id: r.highlightid,
                    content: r.content,
                    created_at: r.created_at
                }
                end
                }.to_json

                send_data json_data,
                            filename: "skookoo_data_#{Date.today}.json",
                            type: "application/json",
                            disposition: "attachment"
            end



            format.pdf do
                pdf = UserDataPdfService.new(user, highlights, replies)

                send_data pdf.render,
                            filename: "skookoo_data_#{Date.today}.pdf",
                            type: "application/pdf",
                            disposition: "attachment"
            end

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
        Expression.where(:userid => session[:user_id]).delete_all


        User.find(session[:user_id]).destroy
        session[:user_id] = nil   
        flash.now[:notice] = "Account deleted"  
        redirect_to root_path
    end



    private

        def user_params
            params.require(:user).permit(:email, :name, :username, :password, :password_confirmation, 
                                         :avatar, :background, :mana, :votes, :darkmode, :font, 
                                         :allownotifications, :emailnotifications, :private_profile,
                                         :hooked, :following, :followers, :bio, :location)
        end

end