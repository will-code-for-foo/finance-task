module Api
  module V1
    module Users
      class BalancesController < ApplicationController
        def show
          render json: { balance: format("%.2f", @current_user.balance_cents.to_d / 100) }, status: :ok
        end
      end
    end
  end
end
