class Mailer < ActionMailer::Base
  default :from => Devise.mailer_sender

  def signup_confirmation(user_id)
    @user = User.find(user_id)
    mail(to: @user.email, subject: "Welcome to OnlineChecklists")
  end

  def support_request(user_id, message, url)
    @user = User.find(user_id)
    @message = message
    @url = url
    mail(to: "support@onlinechecklists.com", subject: "OnlineChecklists support request from #{@user.email}")
  end
end

