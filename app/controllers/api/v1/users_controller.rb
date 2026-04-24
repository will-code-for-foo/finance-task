module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authenticate_request!, only: [:create]

      def create
        @user = User.new(user_params)

        if @user.save
          token = JsonWebToken.encode(user_id: @user.id)
          render json: { user: user_response(@user), token: token }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:email)
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email,
          balance_cents: user.balance_cents,
          created_at: user.created_at
        }
      end
    end
  end
end
