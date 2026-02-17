class SubscriptionsController < ApplicationController
  before_action :authorize_user!

  def new
    # Render your pricing partial (e.g., in views/subscriptions/new.html.erb)
  end

  def create
    # Ensure the user has a subscription record (fallback creation)
    subscription = current_user.subscription
    if subscription.nil?
      subscription = current_user.create_subscription!(
        plan: 'janitor',
        status: 'active'
      )
    end

    # Now safely get or create Stripe customer
    customer = if subscription.stripe_customer_id.present?
                Stripe::Customer.retrieve(subscription.stripe_customer_id)
              else
                Stripe::Customer.create(email: current_user.email)
              end

    # Save the customer ID if it was newly created
    if subscription.stripe_customer_id.blank?
      subscription.update!(stripe_customer_id: customer.id)
    end

    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{
        quantity: 1,
        price: 'price_1T1t47FOghis7e2VrM8vvLXt' 
      }],
      success_url: root_url + '?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: subscriptions_new_url
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    flash[:alert] = "Payment setup failed: #{e.message}"
    redirect_to subscriptions_new_path
  end

end