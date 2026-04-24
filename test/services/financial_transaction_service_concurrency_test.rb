require "test_helper"

class FinancialTransactionServiceConcurrencyTest < ActiveSupport::TestCase
  setup do
    @alice = User.create!(email: "alice_concurrency@example.com", balance_cents: 500)
  end

  # Simulates a race condition: the Ruby object holds a stale balance_cents = 500,
  # while another process has already drained the account to 50 in the database.
  # lock! must reload the fresh value before the funds check — if raise were placed
  # before lock!, the stale value would pass the check and allow a negative balance.
  test "withdrawal reads fresh balance via lock!, not stale in-memory value" do
    sender = User.find(@alice.id)             # balance_cents = 500 in Ruby object

    # Another process drains the account directly (bypasses callbacks/Ruby object)
    User.where(id: sender.id).update_all(balance_cents: 50)
    # sender.balance_cents is still 500 (stale); database is now 50

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
    bob    = User.create!(email: "bob_concurrency@example.com", balance_cents: 0)
    sender = User.find(@alice.id)             # balance_cents = 500 in Ruby object

    User.where(id: sender.id).update_all(balance_cents: 50)

    service = FinancialTransactionService.new(
      transaction_type: "transfer",
      amount_cents: 400,
      sender: sender,
      receiver: bob
    )

    assert_raises(FinancialTransactionService::InsufficientFundsError) { service.call }
    assert_equal 50, @alice.reload.balance_cents
    assert_equal 0,  bob.reload.balance_cents
  ensure
    bob&.destroy
  end
end
