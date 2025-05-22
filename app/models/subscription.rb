class Subscription < ApplicationRecord
  belongs_to :user

  enum status: { pending: 'pending', active: 'active', failed: 'failed', cancelled: 'cancelled' }

  validates :amount, numericality: { greater_than: 0 }
end
