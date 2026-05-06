require "test_helper"

module Api
  module V1
    module Users
      class TransactionsControllerTest < ActionDispatch::IntegrationTest
        test "creates a deposit and returns 201 with transaction and updated balance" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_transactions_url,
            params: { transaction: { type: "deposit", amount: "5.00" } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :created
          json = response.parsed_body
          assert_equal "deposit", json["transaction"]["transaction_type"]
          assert_equal "5.00", json["transaction"]["amount"]
          assert_equal "15.00", json["balance"]
        end

        test "creates a withdrawal and returns 201 with transaction and updated balance" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_transactions_url,
            params: { transaction: { type: "withdrawal", amount: "5.00" } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :created
          json = response.parsed_body
          assert_equal "withdrawal", json["transaction"]["transaction_type"]
          assert_equal "5.00", json["transaction"]["amount"]
          assert_equal "5.00", json["balance"]
        end

        test "returns 422 when withdrawal exceeds balance" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_transactions_url,
            params: { transaction: { type: "withdrawal", amount: "9999.99" } },
            headers: { "Authorization" => "Bearer #{token}" },
            as: :json

          assert_response :unprocessable_entity
          json = response.parsed_body
          assert json["error"].present?
        end

        test "returns 401 when no token provided" do
          post api_v1_transactions_url,
            params: { transaction: { type: "deposit", amount: "5.00" } },
            as: :json

          assert_response :unauthorized
        end

        test "returns 422 for invalid transaction type" do
          user = users(:one)
          token = JsonWebToken.encode(user_id: user.id)

          post api_v1_transactions_url,
            params: { transaction: { type: "transfer", amount: "1.00" } },
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
