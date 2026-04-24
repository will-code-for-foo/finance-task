class Transaction < ApplicationRecord
  TRANSACTION_TYPES = %w[deposit withdrawal transfer].freeze

  belongs_to :sender, class_name: "User", optional: true
  belongs_to :receiver, class_name: "User", optional: true

  validates :amount_cents, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }
  validate :sender_and_receiver_must_differ

  private

  def sender_and_receiver_must_differ
    return unless sender_id.present? && receiver_id.present?

    if sender_id == receiver_id
      errors.add(:receiver_id, "must be different from sender")
    end
  end
end
