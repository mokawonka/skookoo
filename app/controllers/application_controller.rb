class ApplicationController < ActionController::Base
    include Pagy::Backend

    before_action :require_user

    before_action :require_pomologist, only: [:premium_action]


    # or home_controller.rb
    def index  # Or your root action
        if params[:session_id]
            session = Stripe::Checkout::Session.retrieve(params[:session_id])
            if session.payment_status == 'paid'
            current_user.subscription.update(
                plan: 'pomologist',
                status: 'active',
                stripe_subscription_id: session.subscription,
                current_period_end: Time.at(session.subscription.current_period_end)
            )
            flash[:notice] = 'Upgrade successful!'
            end
        end
    end


    def require_pomologist
        redirect_to subscriptions_new_path, alert: 'Upgrade to Pomologist!' unless current_user.pomologist?
    end


    # helpers functions to be used on all controllers
    helper_method :current_user, :logged_in?
    def current_user
        @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    end

    
    def logged_in?
        !!current_user
    end
    
    def require_user
        if !logged_in?
            flash[:alert] = "You must be logged in to perform that action."
            redirect_to login_path
        end
    end

    def authorize_user!
        redirect_to root_path unless session[:user_id].present?
    end


    def check_timestamp
        if logged_in?

            @delta = Time.now - Time.parse(current_user.updated_at.to_s)
            if @delta < 2.seconds
                respond_to do |format|
                    format.js {render "layouts/check_timestamp"}
                end
            end
            
        end
    end

end
