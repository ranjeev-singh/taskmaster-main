module Api
  module V1
    class SubscriptionsController < ApplicationController
      
      before_action :authenticate_user!
      after_action :verify_authorized

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

      private

      def subscription_params
        params.require(:subscription).permit(:user_id, :amount, :currency, :remarks)
      end
    end
  end
end