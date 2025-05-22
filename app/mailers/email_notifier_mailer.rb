class EmailNotifierMailer < ApplicationMailer
  default from: 'no-reply@taskmaster.com'
 
  def notify(email_notification)
    @body = email_notification.body
    mail(to: email_notification.email, subject: email_notification.subject)
  end
end
