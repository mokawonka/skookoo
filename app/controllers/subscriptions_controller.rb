class SubscriptionsController < ApplicationController

  def new
    # Render your pricing partial (e.g., in views/subscriptions/new.html.erb)
  end



def create
  subscription = current_user.subscription || current_user.create_subscription!(
    plan: 'janitor',
    status: 'active'
  )

  # Early exit if already on Pomologist
  if current_user.pomologist?
    Rails.logger.info "Blocked upgrade attempt for user #{current_user.id} (already pomologist)"
    redirect_to root_path, notice: "You already have an active Pomologist plan."
    return
  end

  # 1. Get or create Stripe customer (first attempt)
  customer = nil

  if subscription.stripe_customer_id.present?
    begin
      customer = Stripe::Customer.retrieve(subscription.stripe_customer_id)
      Rails.logger.info "[Stripe] Successfully retrieved existing customer: #{customer.id}"
    rescue Stripe::InvalidRequestError, Stripe::StripeError => e
      Rails.logger.warn "[Stripe] Failed to retrieve customer #{subscription.stripe_customer_id}: #{e.class} - #{e.message}"
      subscription.update_column(:stripe_customer_id, nil)
      customer = nil
    end
  end

  # Create new customer if needed
  if customer.nil?
    begin
      customer = Stripe::Customer.create(email: current_user.email)
      Rails.logger.info "[Stripe] Created new Stripe customer: #{customer.id}"
      subscription.update_column(:stripe_customer_id, customer.id)
    rescue Stripe::StripeError => e
      Rails.logger.error "[Stripe] Failed to create customer: #{e.message}"
      flash[:alert] = "Payment setup failed: #{e.message}"
      redirect_to subscriptions_new_path
      return
    end
  end

  # 2. CRITICAL: Re-validate customer right before Checkout creation
  begin
    customer = Stripe::Customer.retrieve(customer.id)  # Re-fetch to confirm it's still valid
    Rails.logger.info "[Stripe] Re-validated customer before checkout: #{customer.id}"
  rescue Stripe::InvalidRequestError, Stripe::StripeError => e
    Rails.logger.warn "[Stripe] Customer became invalid during flow: #{e.message}"
    subscription.update_column(:stripe_customer_id, nil)
    customer = Stripe::Customer.create(email: current_user.email)
    subscription.update_column(:stripe_customer_id, customer.id)
    Rails.logger.info "[Stripe] Created replacement customer after validation failure: #{customer.id}"
  end

  # 3. Check for existing active/trialing/past_due subscription
  existing_subs = Stripe::Subscription.list(
    customer: customer.id,
    status: 'all',
    limit: 10
  )

  active_subscription = existing_subs.data.find do |s|
    %w[active trialing past_due].include?(s.status)
  end

  # If active sub exists → redirect to portal
  if active_subscription
    portal_session = Stripe::BillingPortal::Session.create(
      customer: customer.id,
      return_url: root_url
    )
    redirect_to portal_session.url, allow_other_host: true
    return
  end

  # 4. No active sub → create new Checkout session
  checkout_session = Stripe::Checkout::Session.create(
    customer: customer.id,
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [{
      quantity: 1,
      price: 'price_1T1t47FOghis7e2VrM8vvLXt'
    }],
    success_url: subscriptions_success_url + '?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: subscriptions_new_url,
    metadata: { user_id: current_user.id.to_s }
  )

  redirect_to checkout_session.url, allow_other_host: true

rescue Stripe::StripeError => e
  Rails.logger.error "Stripe error in create: #{e.message} - #{e.json_body.inspect if e.respond_to?(:json_body)}"
  flash[:alert] = "Payment setup failed: #{e.message}"
  redirect_to subscriptions_new_path
end



def success
  if params[:session_id].present? && params[:session_id] != '{CHECKOUT_SESSION_ID}'  # Guard against placeholder/manual access
    begin
      session = Stripe::Checkout::Session.retrieve(params[:session_id])
      if session.payment_status == 'paid' && session.mode == 'subscription'
        stripe_subscription = Stripe::Subscription.retrieve(session.subscription)
        sub = current_user.subscription
        update_params = {
          plan: 'pomologist', 
          status: 'active',
          stripe_subscription_id: stripe_subscription.id
        }
        if stripe_subscription.respond_to?(:current_period_end) && stripe_subscription.current_period_end.present?
          update_params[:current_period_end] = Time.at(stripe_subscription.current_period_end)
        end
        sub.update!(update_params)
        flash[:notice] = "Upgrade successful!"
      end
    rescue Stripe::InvalidRequestError => e
      flash[:alert] = "Invalid session: #{e.message}"  # Handle bad ID
    rescue NoMethodError => e
      flash[:alert] = "Subscription update failed: #{e.message}"
    end
  else
    flash[:alert] = "No valid session ID provided."
  end
  redirect_to root_path
end





def downgrade
  subscription = current_user.subscription

  if subscription.nil? || subscription.plan != 'pomologist' || subscription.stripe_subscription_id.blank?
    flash[:alert] = "No active Pomologist subscription to downgrade."
    redirect_to root_path
    return
  end

  begin
    # Retrieve the Stripe subscription object
    stripe_sub = Stripe::Subscription.retrieve(subscription.stripe_subscription_id)

    if stripe_sub.status == 'active'
      # Cancel the subscription (correct method in recent Stripe gem versions)
      stripe_sub.cancel  # This cancels it immediately

      # Alternative: cancel at period end (uncomment if preferred)
      # stripe_sub.cancel_at_period_end = true
      # stripe_sub.save

      # Update your local record to janitor (free/active)
      subscription.update!(
        plan: 'janitor',
        status: 'active',
        stripe_subscription_id: nil,   # Optional: clear Stripe ID
        current_period_end: nil        # Optional: clear end date
      )

      flash[:notice] = "Downgraded to Janitor successfully."
    else
      flash[:alert] = "Subscription is not active (current status: #{stripe_sub.status})."
    end
  rescue Stripe::StripeError => e
    flash[:alert] = "Downgrade failed: #{e.message}"
  rescue StandardError => e
    flash[:alert] = "Unexpected error: #{e.message}"
  end

  redirect_to root_path
end

end

