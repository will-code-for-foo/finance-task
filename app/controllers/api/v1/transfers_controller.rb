module Api
  module V1
    class TransfersController < ApplicationController
      def create
        transaction = FinancialTransactionService.for_transfer(
          sender:         @current_user,
          receiver_email: transfer_params[:receiver_email],
          amount_cents:   (transfer_params[:amount].to_d * 100).round.to_i
        ).call

        render json: { transaction: transaction_response(transaction) }, status: :created
      end

      private

      def transfer_params
        params.require(:transfer).permit(:receiver_email, :amount)
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
