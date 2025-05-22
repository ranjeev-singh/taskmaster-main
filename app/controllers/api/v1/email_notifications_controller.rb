module Api
  module v1
    class EmailNotificationsController < ApplicationController
      def create
        email_notification = EmailNotifications::SendService.new(email_notification_params).call
        render json: { message: 'Email sent successfully' }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
     
      private
     
      def email_notification_params
        params.require(:email_notification).permit(:email, :subject, :body)
      end
    end
  end
end