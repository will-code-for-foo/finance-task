module Api
  module V1
    class TransfersController < ApplicationController
      def create
        sender_id   = transfer_params[:sender_id]
        receiver_id = transfer_params[:receiver_id]

        unless @current_user.id.to_s == sender_id.to_s
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end

        begin
          amount_cents = Integer(transfer_params[:amount_cents])
        rescue ArgumentError, TypeError
          render json: { error: "amount_cents must be an integer" }, status: :unprocessable_entity
          return
        end

        receiver = User.find(receiver_id)

        transaction = FinancialTransactionService.new(
          transaction_type: "transfer",
          amount_cents:     amount_cents,
          sender:           @current_user,
          receiver:         receiver
        ).call

        render json: { transaction: transaction_response(transaction) }, status: :created
      rescue FinancialTransactionService::InsufficientFundsError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Receiver not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
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
