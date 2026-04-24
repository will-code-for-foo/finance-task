require "test_helper"

class FinancialTransactionServiceTest < ActiveSupport::TestCase
  def setup
    @alice = User.create!(email: "alice_svc@example.com", balance_cents: 1000)
    @bob   = User.create!(email: "bob_svc@example.com",   balance_cents: 500)
  end

  # ---------------------------------------------------------------------------
  # DEPOSIT
  # ---------------------------------------------------------------------------

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

  test "deposit with amount equal to zero raises ArgumentError and does not change balance" do
    service = FinancialTransactionService.new(
      transaction_type: "deposit",
      amount_cents: 0,
      receiver: @alice
    )
    assert_raises(ArgumentError) { service.call }
    assert_equal 1000, @alice.reload.balance_cents
  end

  test "deposit with negative amount raises ArgumentError and does not change balance" do
    service = FinancialTransactionService.new(
      transaction_type: "deposit",
      amount_cents: -100,
      receiver: @alice
    )
    assert_raises(ArgumentError) { service.call }
    assert_equal 1000, @alice.reload.balance_cents
  end

  test "deposit without receiver raises ArgumentError" do
    service = FinancialTransactionService.new(transaction_type: "deposit", amount_cents: 100)
    assert_raises(ArgumentError) { service.call }
  end

  # ---------------------------------------------------------------------------
  # WITHDRAWAL
  # ---------------------------------------------------------------------------

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

  test "withdrawal without sender raises ArgumentError" do
    service = FinancialTransactionService.new(transaction_type: "withdrawal", amount_cents: 100)
    assert_raises(ArgumentError) { service.call }
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

  # ---------------------------------------------------------------------------
  # TRANSFER
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # MISSING / INVALID PARTICIPANTS FOR TRANSFER
  # ---------------------------------------------------------------------------

  test "transfer without sender raises ArgumentError" do
    service = FinancialTransactionService.new(transaction_type: "transfer", amount_cents: 100, receiver: @bob)
    assert_raises(ArgumentError) { service.call }
  end

  test "transfer without receiver raises ArgumentError" do
    service = FinancialTransactionService.new(transaction_type: "transfer", amount_cents: 100, sender: @alice)
    assert_raises(ArgumentError) { service.call }
  end

  test "transfer with same sender and receiver raises ArgumentError" do
    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 100,
      sender: @alice,
      receiver: @alice
    )
    assert_raises(ArgumentError) { service.call }
  end

  # ---------------------------------------------------------------------------
  # UNKNOWN TRANSACTION TYPE
  # ---------------------------------------------------------------------------

  test "unknown transaction type raises ArgumentError" do
    service = FinancialTransactionService.new(
      transaction_type: "refund",
      amount_cents: 100,
      receiver: @alice
    )
    assert_raises(ArgumentError) { service.call }
  end

  test "unknown transaction type does not create a Transaction record" do
    service = FinancialTransactionService.new(
      transaction_type: "refund",
      amount_cents: 100,
      receiver: @alice
    )
    assert_no_difference "Transaction.count" do
      assert_raises(ArgumentError) { service.call }
    end
  end
end
