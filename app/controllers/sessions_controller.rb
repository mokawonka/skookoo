class SessionsController < ApplicationController
  skip_before_action :require_user, only: [:create, :destroy]

    def create
        user = User.find_by(username: params[:session][:username].downcase)
        
        if user && user.authenticate(params[:session][:password])
          session[:user_id] = user.id
          redirect_to documents_path , notice:  "Logged in successfully."
        else
          redirect_to login_path, alert: "Invalid username or password."
        end

    end
       
    def destroy
      session[:user_id] = nil
      flash[:notice] = "You have been logged out."
      redirect_to root_path
    end

end