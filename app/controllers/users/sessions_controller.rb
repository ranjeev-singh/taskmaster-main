# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    # binding.pry
    # token = JWT.encode(resource.id, Rails.application.secrets.secret_key_base)
    render json: {
      status: {code: 200, message: 'Logged in sucessfully.'},
      data: resource, token: request.env['warden-jwt_auth.token']
    }, status: :ok
  end

  def respond_to_on_destroy
    if current_user
      render json: {
        status: 200,
        message: "logged out successfully"
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end

end
