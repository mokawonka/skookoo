class PasswordResetsController < ApplicationController
  skip_before_action :require_user

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user
      user.generate_password_reset_token
      UserMailer.reset_email(user).deliver_later
    end
    redirect_to login_path, notice: "If that email exists, a reset link has been sent."
  end

  def edit
    @user = User.find_by(reset_password_token: params[:id])
    if @user.nil? || @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: "Reset link is invalid or has expired."
    end
  end

  def update
    @user = User.find_by(reset_password_token: params[:id])

    if @user.nil? || @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: "Reset link is invalid or has expired."
      return
    end

    if @user.update(password_params)
      @user.update_columns(reset_password_token: nil, reset_password_sent_at: nil)
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Password updated successfully."
    else
      flash.now[:alert] = @user.errors.full_messages.join(" • ")
      render :edit
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end