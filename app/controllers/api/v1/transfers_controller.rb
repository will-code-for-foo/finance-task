module Api
  module V1
    class TransfersController < ApplicationController
      def create
        transaction = FinancialTransactionService.for_transfer(
          sender:      @current_user,
          receiver_id: transfer_params[:receiver_id],
          amount_cents: transfer_params[:amount_cents]
        ).call

        render json: { transaction: transaction_response(transaction) }, status: :created
      end

      private

      def transfer_params
        params.require(:transfer).permit(:receiver_id, :amount_cents)
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
