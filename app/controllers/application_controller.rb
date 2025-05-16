class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def user_not_authorized
    render json: { alert: ['You are not authorized to perform this operation.'] }, status: :forbidden
  end

end
