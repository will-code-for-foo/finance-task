require "test_helper"

module Api
  module V1
    module Users
      class BalancesControllerTest < ActionDispatch::IntegrationTest
        # GET /api/v1/users/:user_id/balance — success
        test "returns 200 with balance_cents when authenticated as correct user" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          get api_v1_user_balance_url(user),
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :ok
          json = response.parsed_body
          assert_equal user.balance_cents, json["balance_cents"]
        end

        # GET /api/v1/users/:user_id/balance — no token
        test "returns 401 when no token provided" do
          user = users(:one)

          get api_v1_user_balance_url(user), as: :json

          assert_response :unauthorized
        end

        # GET /api/v1/users/:user_id/balance — different user
        test "returns 403 when authenticated as a different user" do
          user = users(:one)
          other_user = users(:two)
          token = JsonWebToken.encode(user_id: other_user.id)

          get api_v1_user_balance_url(user),
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :forbidden
        end

        # GET /api/v1/users/:user_id/balance — user not found
        test "returns 404 when user does not exist" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          get api_v1_user_balance_url(user_id: SecureRandom.uuid),
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :not_found
        end
      end
    end
  end
end
