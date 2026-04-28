module Api
  module V1
    class TransfersController < ApplicationController
      def create
        unless @current_user.id.to_s == transfer_params[:sender_id].to_s
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end

        receiver = User.find(transfer_params[:receiver_id])

        transaction = FinancialTransactionService.new(
          transaction_type: "transfer",
          amount_cents:     transfer_params[:amount_cents],
          sender:           @current_user,
          receiver:         receiver
        ).call

        render json: { transaction: transaction_response(transaction) }, status: :created
      end

      private

      def transfer_params
        params.require(:transfer).permit(:sender_id, :receiver_id, :amount_cents)
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
