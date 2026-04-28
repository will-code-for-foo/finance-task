module Api
  module V1
    module Users
      class TransactionsController < ApplicationController
        before_action :find_and_authorize_user!

        def create
          transaction = FinancialTransactionService.for_user_transaction(
            user:             @user,
            transaction_type: transaction_params[:type],
            amount_cents:     transaction_params[:amount_cents]
          ).call

          render json: {
            transaction: transaction_response(transaction),
            balance_cents: @user.reload.balance_cents
          }, status: :created
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
