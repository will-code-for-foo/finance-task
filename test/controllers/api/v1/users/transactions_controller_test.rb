require "test_helper"

module Api
  module V1
    module Users
      class TransactionsControllerTest < ActionDispatch::IntegrationTest
        # POST /api/v1/users/:user_id/transactions — deposit success
        test "creates a deposit and returns 201 with transaction and updated balance" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_user_transactions_url(user),
            params: { transaction: { type: "deposit", amount_cents: 500 } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :created
          json = response.parsed_body
          assert_equal "deposit", json["transaction"]["transaction_type"]
          assert_equal 500, json["transaction"]["amount_cents"]
          assert_nil json["transaction"]["sender_id"]
          assert_equal user.id, json["transaction"]["receiver_id"]
          assert_equal user.balance_cents + 500, json["balance_cents"]
        end

        # POST /api/v1/users/:user_id/transactions — withdrawal success
        test "creates a withdrawal and returns 201 with transaction and updated balance" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_user_transactions_url(user),
            params: { transaction: { type: "withdrawal", amount_cents: 500 } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :created
          json = response.parsed_body
          assert_equal "withdrawal", json["transaction"]["transaction_type"]
          assert_equal 500, json["transaction"]["amount_cents"]
          assert_equal user.id, json["transaction"]["sender_id"]
          assert_nil json["transaction"]["receiver_id"]
          assert_equal user.balance_cents - 500, json["balance_cents"]
        end

        # POST /api/v1/users/:user_id/transactions — insufficient funds
        test "returns 422 when withdrawal exceeds balance" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_user_transactions_url(user),
            params: { transaction: { type: "withdrawal", amount_cents: 999_999 } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :unprocessable_entity
          json = response.parsed_body
          assert json["error"].present?
        end

        # POST /api/v1/users/:user_id/transactions — no token
        test "returns 401 when no token provided" do
          user = users(:one)

          post api_v1_user_transactions_url(user),
            params: { transaction: { type: "deposit", amount_cents: 500 } },
            as: :json

          assert_response :unauthorized
        end

        # POST /api/v1/users/:user_id/transactions — user not found
        test "returns 404 when user does not exist" do
          token = JsonWebToken.encode(user_id: users(:one).id)

          post api_v1_user_transactions_url(user_id: SecureRandom.uuid),
            params: { transaction: { type: "deposit", amount_cents: 500 } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :not_found
        end

        # POST /api/v1/users/:user_id/transactions — invalid type
        test "returns 422 for invalid transaction type" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_user_transactions_url(user),
            params: { transaction: { type: "transfer", amount_cents: 100 } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :unprocessable_entity
          json = response.parsed_body
          assert json["error"].present?
        end
      end
    end
  end
end
