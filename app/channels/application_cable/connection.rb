module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token] || request.headers['Authorization']&.split(' ')&.last
      if token
        decoded_token = JWT.decode(token, Rails.application.credentials.fetch(:secret_key_base), true)
        jti = decoded_token.first['jti']
        user = User.find_by(jti: jti) rescue reject_unauthorized_connection
      else
        reject_unauthorized_connection
      end
    end
  end
end