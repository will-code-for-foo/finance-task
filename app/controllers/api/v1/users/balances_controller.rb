module Api
  module V1
    module Users
      class BalancesController < ApplicationController
        def show
          render json: { balance_cents: @current_user.balance_cents }, status: :ok
        end
      end
    end
  end
end
