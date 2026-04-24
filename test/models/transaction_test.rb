require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    @sender   = User.create!(email: "sender_tx@example.com")
    @receiver = User.create!(email: "receiver_tx@example.com")
  end

  # --- Table structure & constraints ---

  test "valid transfer transaction is persisted" do
    tx = Transaction.new(
      sender: @sender,
      receiver: @receiver,
      amount_cents: 100,
      transaction_type: "transfer"
    )
    assert tx.valid?
    assert tx.save
    assert_not_nil tx.id
  end

  test "deposit has nil sender_id" do
    tx = Transaction.create!(
      sender_id: nil,
      receiver: @receiver,
      amount_cents: 500,
      transaction_type: "deposit"
    )
    assert_nil tx.sender_id
  end

  test "withdrawal has nil receiver_id" do
    tx = Transaction.create!(
      sender: @sender,
      receiver_id: nil,
      amount_cents: 200,
      transaction_type: "withdrawal"
    )
    assert_nil tx.receiver_id
  end

  # --- amount_cents > 0 ---

  test "amount_cents must be greater than zero" do
    tx = Transaction.new(
      receiver: @receiver,
      amount_cents: 0,
      transaction_type: "deposit"
    )
    assert_not tx.valid?
    assert_includes tx.errors[:amount_cents], "must be greater than 0"
  end

  test "negative amount_cents is invalid" do
    tx = Transaction.new(
      receiver: @receiver,
      amount_cents: -50,
      transaction_type: "deposit"
    )
    assert_not tx.valid?
  end

  test "amount_cents must be present" do
    tx = Transaction.new(
      receiver: @receiver,
      transaction_type: "deposit"
    )
    assert_not tx.valid?
  end

  # --- transaction_type validation ---

  test "transaction_type must be valid" do
    tx = Transaction.new(
      receiver: @receiver,
      amount_cents: 100,
      transaction_type: "refund"
    )
    assert_not tx.valid?
  end

  # --- sender and receiver must differ ---

  test "sender_id and receiver_id cannot be the same" do
    tx = Transaction.new(
      sender: @sender,
      receiver: @sender,
      amount_cents: 100,
      transaction_type: "transfer"
    )
    assert_not tx.valid?
    assert_includes tx.errors[:receiver_id], "must be different from sender"
  end

  test "same sender and receiver is invalid even with UUID strings" do
    id = @sender.id
    tx = Transaction.new(
      sender_id: id,
      receiver_id: id,
      amount_cents: 100,
      transaction_type: "transfer"
    )
    assert_not tx.valid?
  end

  # --- ActiveRecord relations ---

  test "belongs_to sender with class_name User" do
    tx = Transaction.create!(sender: @sender, receiver: @receiver, amount_cents: 50, transaction_type: "transfer")
    assert_equal @sender, tx.sender
    assert_instance_of User, tx.sender
  end

  test "belongs_to receiver with class_name User" do
    tx = Transaction.create!(sender: @sender, receiver: @receiver, amount_cents: 50, transaction_type: "transfer")
    assert_equal @receiver, tx.receiver
    assert_instance_of User, tx.receiver
  end
end
