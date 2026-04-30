module Api
  module V1
    module Users
      class TransactionsController < ApplicationController
        def create
          transaction = FinancialTransactionService.for_user_transaction(
            user:             @current_user,
            transaction_type: transaction_params[:type],
            amount_cents:     parse_amount!(transaction_params[:amount])
          ).call

          render json: {
            transaction: transaction_response(transaction),
            balance: @current_user.reload.balance_cents.to_f / 100
          }, status: :created
        end

        private

        def transaction_params
          params.require(:transaction).permit(:type, :amount)
        end

        def transaction_response(transaction)
          {
            transaction_type: transaction.transaction_type,
            amount:           transaction.amount_cents.to_f / 100,
            created_at:       transaction.created_at
          }
        end
      end
    end
  end
end
