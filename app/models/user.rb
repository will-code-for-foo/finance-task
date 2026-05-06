class User < ApplicationRecord
  EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  before_validation { self.email = email.to_s.downcase.strip }

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false, message: "already exists" },
                    format: { with: EMAIL_REGEX }
  validates :balance_cents, numericality: { greater_than_or_equal_to: 0 }
end
