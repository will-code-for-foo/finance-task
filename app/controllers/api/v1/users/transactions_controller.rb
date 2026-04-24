module Api
  module V1
    module Users
      class TransactionsController < ApplicationController
        ALLOWED_TYPES = %w[deposit withdrawal].freeze

        def create
          @user = User.find(params[:user_id])

          type         = transaction_params[:type]
          amount_cents = transaction_params[:amount_cents].to_i

          unless ALLOWED_TYPES.include?(type)
            render json: { error: "Invalid transaction type. Must be deposit or withdrawal." }, status: :unprocessable_entity
            return
          end

          sender   = type == "withdrawal" ? @user : nil
          receiver = type == "deposit"    ? @user : nil

          transaction = FinancialTransactionService.new(
            transaction_type: type,
            amount_cents:     amount_cents,
            sender:           sender,
            receiver:         receiver
          ).call

          render json: {
            transaction: transaction_response(transaction),
            balance_cents: @user.reload.balance_cents
          }, status: :created
        rescue FinancialTransactionService::InsufficientFundsError => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end

        private

        def transaction_params
          params.require(:transaction).permit(:type, :amount_cents)
        end

        def transaction_response(transaction)
          {
            id:               transaction.id,
            transaction_type: transaction.transaction_type,
            amount_cents:     transaction.amount_cents,
            sender_id:        transaction.sender_id,
            receiver_id:      transaction.receiver_id,
            created_at:       transaction.created_at
          }
        end
      end
    end
  end
end
