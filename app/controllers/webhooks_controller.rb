class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token  # In production, verify signature below

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
      )
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      head :bad_request
      return
    end

    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      user = User.find_by(id: session.metadata['user_id'])
      if user && user.subscription
        user.subscription.update!(
          plan: 'pomologist',
          status: 'active',
          stripe_subscription_id: session.subscription,
          current_period_end: Time.at(session.subscription.current_period_end)
        )
      end
    when 'invoice.payment_succeeded'
      # Renewal: Update current_period_end
    when 'invoice.payment_failed'
      subscription = Subscription.find_by(stripe_subscription_id: event.data.object.subscription)
      subscription&.update(status: 'past_due')
    when 'customer.subscription.deleted'
      subscription = Subscription.find_by(stripe_subscription_id: event.data.object.id)
      subscription&.update(status: 'canceled', plan: 'janitor')
    end

    head :ok
  end
end