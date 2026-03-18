class SessionsController < ApplicationController
  skip_before_action :require_user, only: [:create, :destroy]


    def create
      login = params[:session][:username].downcase.strip

      user = User.find_by(username: login) || User.find_by(email: login)

      if user&.authenticate(params[:session][:password])
        session[:user_id] = user.id
        return_to = session.delete(:return_to) || params[:return_to] || root_path
        redirect_to return_to, notice: "Logged in successfully."
      else
        redirect_to login_path, alert: "Invalid username or password."
      end
    end


       
    def destroy
      reset_session
      flash[:notice] = "You have been logged out."
      redirect_to root_path
    end

end