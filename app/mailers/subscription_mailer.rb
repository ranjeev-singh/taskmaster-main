class SubscriptionMailer < ApplicationMailer
  default from: 'no-reply@tasker.com'

  def subscription_success_email(subscription)
    @subscription = subscription
    @user = subscription.user

    mail(
      to: @user.email,
      subject: "Your subscription was successful"
    )
  end

  def subscription_failed_email(subscription)
    @subscription = subscription
    @user = subscription.user

    mail(
      to: @user.email,
      subject: "Subscription failed"
    )
  end
end
