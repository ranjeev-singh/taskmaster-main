class SubscriptionService
  def initialize(user:, amount:, currency: 'usd', remarks: nil)
    @user = user
    @amount = amount
    @currency = currency
    @remarks = remarks
  end

  def call
    begin
      customer = create_or_fetch_customer
      price = create_price
      stripe_subscription = Stripe::Subscription.create({
        customer: customer.id,
        items: [{ price: price.id }],
        payment_behavior: 'default_incomplete',
        expand: ['latest_invoice.payment_intent'],
      })

      subscription = Subscription.create!(
        user: @user,
        amount: @amount,
        currency: @currency,
        status: 'active',
        stripe_subscription_id: stripe_subscription.id,
        remarks: @remarks
      )

      SubscriptionMailer.subscription_success_email(subscription).deliver_later
      subscription

    rescue => e
      subscription = Subscription.create!(
        user: @user,
        amount: @amount,
        currency: @currency,
        status: 'failed',
        stripe_subscription_id: nil,
        remarks: "Stripe error: #{e.message}"
      )

      SubscriptionMailer.subscription_failed_email(subscription).deliver_later
      subscription
    end
  end

  private
  def create_or_fetch_customer
    if @user.stripe_customer_id.present?
      Stripe::Customer.retrieve(@user.stripe_customer_id)
    else
      customer = Stripe::Customer.create(email: @user.email)
      @user.update(stripe_customer_id: customer.id)
      customer
    end
  end

  def create_price
    Stripe::Price.create(
      unit_amount: (@amount * 100).to_i,
      currency: @currency,
      recurring: { interval: 'month' },
      product_data: { name: "Subscription for #{@user.email}" }
    )
  end
end

