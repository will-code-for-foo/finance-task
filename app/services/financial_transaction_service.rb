class FinancialTransactionService
  class InsufficientFundsError < StandardError; end

  def initialize(transaction_type:, amount_cents:, sender: nil, receiver: nil)
    @transaction_type = transaction_type
    @amount_cents = amount_cents
    @sender = sender
    @receiver = receiver
  end

  def call
    ActiveRecord::Base.transaction do
      case @transaction_type
      when "deposit"
        perform_deposit
      when "withdrawal"
        perform_withdrawal
      when "transfer"
        perform_transfer
      else
        raise ArgumentError, "Unknown transaction type: #{@transaction_type}"
      end
    end
  end

  private

  def perform_deposit
    @receiver.lock!
    @receiver.balance_cents += @amount_cents
    @receiver.save!
    Transaction.create!(
      receiver: @receiver,
      amount_cents: @amount_cents,
      transaction_type: "deposit"
    )
  end

  def perform_withdrawal
    @sender.lock! # lock and reload sender to get fresh balance_cents value for funds check
    raise InsufficientFundsError, "Insufficient funds for withdrawal" if @sender.balance_cents < @amount_cents

    @sender.balance_cents -= @amount_cents
    @sender.save!
    Transaction.create!(
      sender: @sender,
      amount_cents: @amount_cents,
      transaction_type: "withdrawal"
    )
  end

  def perform_transfer
    # Lock both rows in a consistent order (by id) to prevent deadlocks
    # when two concurrent transfers involve the same pair of users.
    # lock! reloads balance_cents for the sender to get fresh value for funds check
    [@sender, @receiver].sort_by(&:id).each(&:lock!)

    raise InsufficientFundsError, "Insufficient funds for transfer" if @sender.balance_cents < @amount_cents

    @sender.balance_cents -= @amount_cents
    @receiver.balance_cents += @amount_cents
    @sender.save!
    @receiver.save!
    Transaction.create!(
      sender: @sender,
      receiver: @receiver,
      amount_cents: @amount_cents,
      transaction_type: "transfer"
    )
  end
end
