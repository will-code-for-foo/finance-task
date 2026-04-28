require "test_helper"

module Api
  module V1
    module Users
      class BalancesControllerTest < ActionDispatch::IntegrationTest
        # GET /api/v1/balance — success
        test "returns 200 with balance_cents when authenticated" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          get api_v1_balance_url,
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :ok
          json = response.parsed_body
          assert_equal user.balance_cents, json["balance_cents"]
        end

        # GET /api/v1/balance — no token
        test "returns 401 when no token provided" do
          get api_v1_balance_url, as: :json

          assert_response :unauthorized
        end
      end
    end
  end
end
