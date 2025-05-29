class Subscription < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[active canceled] }
  validates :currency, presence: true
  validates :stripe_subscription_id, presence: true, uniqueness: true, allow_nil: true
end
