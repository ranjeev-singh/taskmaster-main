# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

      # def create
      #   user = User.new(sign_up_params)
      #   if user.save
      #     token = Warden::JWTAuth::UserEncoder.new.call(user, nil, nil)[0]
      #     user.role = params[:user][:role] if params[:user][:role].present?
      #     render json: { token: token, user: { email: user.email, role: user.role } }, status: :created
      #   else
      #     render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      #   end
      # end

      # private

      # def sign_up_params
      #   params.require(:user).permit(:email, :password, :password_confirmation, :role)
      # end

  def respond_with(resource, _opts = {})
    if request.method == "POST" && resource.persisted?
      render json: {
        status: {code: 200, message: "Signed up sucessfully."},
        data: resource
      }, status: :ok
    elsif request.method == "DELETE"
      render json: {
        status: { code: 200, message: "Account deleted successfully."}
      }, status: :ok
    else
      render json: {
        status: {code: 422, message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}"}
      }, status: :unprocessable_entity
    end
  end
end
