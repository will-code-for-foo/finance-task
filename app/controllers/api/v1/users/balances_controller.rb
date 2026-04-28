module Api
  module V1
    module Users
      class BalancesController < ApplicationController
        before_action :find_and_authorize_user!

        def show
          render json: { balance_cents: @user.balance_cents }, status: :ok
        end
      end
    end
  end
end
