module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate_request!

      def create
        user = User.find_by(email: session_params[:email].to_s.downcase.strip)

        if user
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token }, status: :ok
        else
          render json: { error: "Invalid email" }, status: :unauthorized
        end
      end

      private

      def session_params
        params.require(:session).permit(:email)
      end
    end
  end
end
