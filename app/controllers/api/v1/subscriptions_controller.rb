module Api
  module V1
    class SubscriptionsController < ApplicationController
      
      before_action :authenticate_user!
      after_action :verify_authorized

      def index
        @subscriptions = current_user.subscriptions
        authorize @subscriptions
        render json: @subscriptions
      end

      def create
        authorize Subscription
        subscription = SubscriptionService.new(
          user: User.find(subscription_params[:user_id]),
          amount: subscription_params[:amount],
          currency: subscription_params[:currency] || 'usd',
          remarks: subscription_params[:remarks]
        ).call

        render json: subscription, status: :created
      end

      def cancel_subscription
        @subscription = Subscription.find_by(user_id: current_user.id, status: 'active')
        authorize @subscription, :cancel_subscription?

        unless @subscription
          render json: { error: 'No active subscription found' }, status: :not_found
          return
        end

        result = SubscriptionService.new(subscription: @subscription).cancel
        if result.success?
          render json: { message: 'Subscription canceled successfully', subscription: @subscription }, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def subscription_params
        params.require(:subscription).permit(:user_id, :amount, :currency, :remarks)
      end
    end
  end
end