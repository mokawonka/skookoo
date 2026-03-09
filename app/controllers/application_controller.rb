class ApplicationController < ActionController::Base
    include Pagy::Backend

    before_action :require_user

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


    # helpers functions to be used on all controllers
    helper_method :current_user, :logged_in?
    def current_user

        if params[:token].present?
            @current_user ||= user_from_token(params[:token])
        end

        # Finally check session
        @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]

        @current_user
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
        return unless logged_in?

        last_action = session[:last_action_at]

        if last_action && Time.current - last_action < 2.seconds
            respond_to do |format|
            format.js { render "layouts/check_timestamp" }
            format.html { redirect_back fallback_location: root_path, alert: "Please retry in 2 seconds" }
            end
            return   #  stops the controller action
        end

        session[:last_action_at] = Time.current
    end

    private

    
    def user_from_token(token = nil)
        token = params[:token].to_s
        return nil if token.blank?

        verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)

        begin
            data = verifier.verify(token)
            Rails.logger.info "Token verified - full data: #{data.inspect}"

            # Handle exp as string or integer (verifier can return string)
            exp_raw = data[:exp] || data['exp']
            exp = exp_raw.to_i
            if exp.zero? || exp < Time.current.to_i
                Rails.logger.warn "Token expired or invalid exp! raw exp: #{exp_raw.inspect}, parsed: #{exp}"
                return nil
            end

            # Handle user_id as string or integer
            user_id = (data[:user_id] || data['user_id']).to_s
            user = User.find_by(id: user_id)
            Rails.logger.info "User found: #{user&.id || 'not found'} (looked for id: #{user_id})"
            user
        rescue => e
            Rails.logger.error "Token verification FAILED: #{e.class} - #{e.message}"
            nil
        end
    end

end
