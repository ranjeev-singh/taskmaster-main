class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :tasks, foreign_key: 'assigned_to_id'
  has_many :subscriptions

  after_create :create_user_api_call
  after_update :update_user_api_call

  enum role: %w{user manager admin}

  def jwt_payload
    super.merge('sub' => id)
  end

  self::roles.keys.each do |k|
    define_method "#{k}?" do
      role == k
    end
  end

  def create_user_api_call
    response = HTTParty.post("http://localhost:4001/api/v1/users", {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        user: {
          email: self.email,
          user_type: self.role
        }
      }.to_json
    })
  end

  def update_user_api_call
    response = HTTParty.put("http://localhost:4001/api/v1/users/1", {
      headers: { 'Content-Type' => 'application/json' },
      body: {
        user: {
          email: self.email,
          user_type: self.role
        }
      }.to_json
    })
  end
end
