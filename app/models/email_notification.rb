class EmailNotification < ApplicationRecord
	validates :email, :subject, :body, presence: true
end
