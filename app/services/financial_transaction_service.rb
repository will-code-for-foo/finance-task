class FinancialTransactionService
  class InsufficientFundsError < StandardError; end
  class InvalidInputError < StandardError; end

  USER_INITIATED_TYPES = %w[deposit withdrawal].freeze

  def self.for_user_transaction(user:, transaction_type:, amount_cents:)
    unless USER_INITIATED_TYPES.include?(transaction_type)
      raise InvalidInputError, "Invalid transaction type. Must be one of: #{USER_INITIATED_TYPES.join(', ')}"
    end

    sender   = transaction_type == "withdrawal" ? user : nil
    receiver = transaction_type == "deposit"    ? user : nil

    new(
      transaction_type: transaction_type,
      amount_cents:     amount_cents,
      sender:           sender,
      receiver:         receiver
    )
  end

  def initialize(transaction_type:, amount_cents:, sender: nil, receiver: nil)
    @transaction_type = transaction_type
    @amount_cents = amount_cents
    @sender = sender
    @receiver = receiver
  end

  def call
    validate_inputs!

    ActiveRecord::Base.transaction do
      case @transaction_type
      when "deposit"
        perform_deposit
      when "withdrawal"
        perform_withdrawal
      when "transfer"
        perform_transfer
      end
    end
  end

  private

  def validate_inputs!
    begin
      @amount_cents = Integer(@amount_cents)
    rescue ArgumentError, TypeError
      raise InvalidInputError, "amount_cents must be a positive integer"
    end
    raise InvalidInputError, "amount_cents must be greater than 0" unless @amount_cents > 0

    case @transaction_type
    when "deposit"
      raise InvalidInputError, "receiver is required for deposit" if @receiver.nil?
    when "withdrawal"
      raise InvalidInputError, "sender is required for withdrawal" if @sender.nil?
    when "transfer"
      raise InvalidInputError, "sender is required for transfer" if @sender.nil?
      raise InvalidInputError, "receiver is required for transfer" if @receiver.nil?
      raise InvalidInputError, "sender and receiver must differ" if @sender.id == @receiver.id
    else
      raise InvalidInputError, "Unknown transaction type: #{@transaction_type}"
    end
  end

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
