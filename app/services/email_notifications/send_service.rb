module EmailNotifications
  class SendService
    def initialize(params)
      @params = params
    end
 
    def call
      email_notification = EmailNotification.create!(@params)
      EmailNotifier.notify(email_notification).deliver_later
      email_notification
    end
  end
end