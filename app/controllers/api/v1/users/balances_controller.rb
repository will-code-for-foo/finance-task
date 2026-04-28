module Api
  module V1
    module Users
      class BalancesController < ApplicationController
        def show
          render json: { balance: @current_user.balance_cents.to_f / 100 }, status: :ok
        end
      end
    end
  end
end
