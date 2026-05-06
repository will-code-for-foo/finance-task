require "test_helper"

class FinancialTransactionServiceTest < ActiveSupport::TestCase
  def setup
    @alice = User.create!(email: "alice_svc@example.com", balance_cents: 1000)
    @bob   = User.create!(email: "bob_svc@example.com",   balance_cents: 500)
  end

  test "deposit increases receiver balance by amount_cents" do
    service = FinancialTransactionService.new(
      transaction_type: "deposit",
      amount_cents: 300,
      receiver: @alice
    )
    service.call
    assert_equal 1300, @alice.reload.balance_cents
  end

  test "deposit creates a Transaction record with correct attributes" do
    service = FinancialTransactionService.new(
      transaction_type: "deposit",
      amount_cents: 200,
      receiver: @alice
    )
    assert_difference "Transaction.count", 1 do
      service.call
    end
    tx = Transaction.last
    assert_equal "deposit", tx.transaction_type
    assert_equal @alice.id, tx.receiver_id
    assert_nil tx.sender_id
    assert_equal 200, tx.amount_cents
  end

  test "deposit with amount equal to zero raises InvalidInputError and does not change balance" do
    service = FinancialTransactionService.new(
      transaction_type: "deposit",
      amount_cents: 0,
      receiver: @alice
    )
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
    assert_equal 1000, @alice.reload.balance_cents
  end

  test "deposit with negative amount raises InvalidInputError and does not change balance" do
    service = FinancialTransactionService.new(
      transaction_type: "deposit",
      amount_cents: -100,
      receiver: @alice
    )
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
    assert_equal 1000, @alice.reload.balance_cents
  end

  test "deposit without receiver raises InvalidInputError" do
    service = FinancialTransactionService.new(transaction_type: "deposit", amount_cents: 100)
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
  end

  test "withdrawal decreases sender balance by amount_cents" do
    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 400,
      sender: @alice
    )
    service.call
    assert_equal 600, @alice.reload.balance_cents
  end

  test "withdrawal creates a Transaction record with correct attributes" do
    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 100,
      sender: @alice
    )
    assert_difference "Transaction.count", 1 do
      service.call
    end
    tx = Transaction.last
    assert_equal "withdrawal", tx.transaction_type
    assert_equal @alice.id, tx.sender_id
    assert_nil tx.receiver_id
    assert_equal 100, tx.amount_cents
  end

  test "withdrawal of exact balance succeeds" do
    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 1000,
      sender: @alice
    )
    service.call
    assert_equal 0, @alice.reload.balance_cents
  end

  test "withdrawal exceeding balance raises InsufficientFundsError" do
    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 1001,
      sender: @alice
    )
    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
  end

  test "withdrawal exceeding balance does not change balance" do
    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 9999,
      sender: @alice
    )
    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
    assert_equal 1000, @alice.reload.balance_cents
  end

  test "withdrawal exceeding balance does not create a Transaction record" do
    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 9999,
      sender: @alice
    )
    assert_no_difference "Transaction.count" do
      assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
    end
  end

  test "withdrawal without sender raises InvalidInputError" do
    service = FinancialTransactionService.new(transaction_type: "withdrawal", amount_cents: 100)
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
  end

  test "withdrawal from zero balance raises InsufficientFundsError" do
    @alice.update!(balance_cents: 0)
    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 1,
      sender: @alice
    )
    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
  end

  test "transfer decreases sender balance and increases receiver balance" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 300,
      sender: @alice,
      receiver: @bob
    )
    service.call
    assert_equal 700,  @alice.reload.balance_cents
    assert_equal 800,  @bob.reload.balance_cents
  end

  test "transfer creates a Transaction record with correct attributes" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 100,
      sender: @alice,
      receiver: @bob
    )
    assert_difference "Transaction.count", 1 do
      service.call
    end
    tx = Transaction.last
    assert_equal "transfer", tx.transaction_type
    assert_equal @alice.id, tx.sender_id
    assert_equal @bob.id,   tx.receiver_id
    assert_equal 100, tx.amount_cents
  end

  test "transfer of exact sender balance succeeds" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 1000,
      sender: @alice,
      receiver: @bob
    )
    service.call
    assert_equal 0,    @alice.reload.balance_cents
    assert_equal 1500, @bob.reload.balance_cents
  end

  test "transfer exceeding sender balance raises InsufficientFundsError" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 1001,
      sender: @alice,
      receiver: @bob
    )
    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
  end

  test "transfer exceeding balance rolls back both balances" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 9999,
      sender: @alice,
      receiver: @bob
    )
    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
    assert_equal 1000, @alice.reload.balance_cents
    assert_equal 500,  @bob.reload.balance_cents
  end

  test "transfer exceeding balance does not create a Transaction record" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 9999,
      sender: @alice,
      receiver: @bob
    )
    assert_no_difference "Transaction.count" do
      assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
    end
  end

  test "total money supply is conserved after transfer" do
    total_before = @alice.balance_cents + @bob.balance_cents
    FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 300,
      sender: @alice,
      receiver: @bob
    ).call
    total_after = @alice.reload.balance_cents + @bob.reload.balance_cents
    assert_equal total_before, total_after
  end

  test "transfer without sender raises InvalidInputError" do
    service = FinancialTransactionService.new(transaction_type: "transfer", amount_cents: 100, receiver: @bob)
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
  end

  test "transfer without receiver raises InvalidInputError" do
    service = FinancialTransactionService.new(transaction_type: "transfer", amount_cents: 100, sender: @alice)
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
  end

  test "transfer with same sender and receiver raises InvalidInputError" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 100,
      sender: @alice,
      receiver: @alice
    )
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
  end

  test "unknown transaction type raises InvalidInputError" do
    service = FinancialTransactionService.new(
      transaction_type: "refund",
      amount_cents: 100,
      receiver: @alice
    )
    assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
  end

  test "unknown transaction type does not create a Transaction record" do
    service = FinancialTransactionService.new(
      transaction_type: "refund",
      amount_cents: 100,
      receiver: @alice
    )
    assert_no_difference "Transaction.count" do
      assert_raises(FinancialTransactionService::InvalidInputError) { service.call }
    end
  end

  # ---------------------------------------------------------------------------
  # STALE OBJECT / PESSIMISTIC LOCKING
  # These tests verify that lock! reloads the balance from the DB before the
  # funds check, simulating what would happen if another process had already
  # mutated the row between when our Ruby object was loaded and when the
  # service runs. No real threads are needed — the stale state is set up
  # directly via update_all.
  # ---------------------------------------------------------------------------

  test "withdrawal reads fresh balance via lock!, not stale in-memory value" do
    sender = User.find(@alice.id)             # balance_cents = 1000 in Ruby object

    # Another process drains the account directly (bypasses Ruby object)
    User.where(id: sender.id).update_all(balance_cents: 50)
    # sender.balance_cents is still 1000 (stale); database is now 50

    service = FinancialTransactionService.new(
      transaction_type: "withdrawal",
      amount_cents: 400,
      sender: sender
    )

    # lock! reloads balance_cents = 50 → 50 < 400 → InsufficientFundsError
    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
    assert_equal 50, @alice.reload.balance_cents
  end

  test "transfer reads fresh sender balance via lock!, not stale in-memory value" do
    sender = User.find(@alice.id)             # balance_cents = 1000 in Ruby object

    User.where(id: sender.id).update_all(balance_cents: 50)

    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 400,
      sender: sender,
      receiver: @bob
    )

    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
    assert_equal 50, @alice.reload.balance_cents
    assert_equal 500, @bob.reload.balance_cents
  end
end
