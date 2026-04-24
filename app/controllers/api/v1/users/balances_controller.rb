module Api
  module V1
    module Users
      class BalancesController < ApplicationController
        def show
          @user = User.find(params[:user_id])

          unless @current_user.id == @user.id
            render json: { error: "Forbidden" }, status: :forbidden
            return
          end

          render json: { balance_cents: @user.balance_cents }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :not_found
        end
      end
    end
  end
end
