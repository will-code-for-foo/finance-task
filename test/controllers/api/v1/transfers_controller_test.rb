require "test_helper"

module Api
  module V1
    class TransfersControllerTest < ActionDispatch::IntegrationTest
      # POST /api/v1/transfers — success
      test "creates a transfer and returns 201 with transaction details" do
        sender   = users(:one)
        receiver = users(:two)
        token    = JsonWebToken.encode(user_id: sender.id)

        post api_v1_transfers_url,
          params: { transfer: { sender_id: sender.id, receiver_id: receiver.id, amount_cents: 200 } },
          headers: { "Authorization" => "Bearer #{token}" },
          as: :json

        assert_response :created
        json = response.parsed_body
        assert_equal "transfer",  json["transaction"]["transaction_type"]
        assert_equal 200,         json["transaction"]["amount_cents"]
        assert_equal sender.id,   json["transaction"]["sender_id"]
        assert_equal receiver.id, json["transaction"]["receiver_id"]

        assert_equal sender.balance_cents   - 200, sender.reload.balance_cents
        assert_equal receiver.balance_cents + 200, receiver.reload.balance_cents
      end

      # POST /api/v1/transfers — no token
      test "returns 401 when no token provided" do
        sender   = users(:one)
        receiver = users(:two)

        post api_v1_transfers_url,
          params: { transfer: { sender_id: sender.id, receiver_id: receiver.id, amount_cents: 100 } },
          as: :json

        assert_response :unauthorized
      end

      # POST /api/v1/transfers — sender_id does not match current_user
      test "returns 403 when sender_id does not match authenticated user" do
        sender   = users(:one)
        receiver = users(:two)
        token    = JsonWebToken.encode(user_id: receiver.id)

        post api_v1_transfers_url,
          params: { transfer: { sender_id: sender.id, receiver_id: receiver.id, amount_cents: 100 } },
          headers: { "Authorization" => "Bearer #{token}" },
          as: :json

        assert_response :forbidden
      end

      # POST /api/v1/transfers — receiver does not exist
      test "returns 404 when receiver does not exist" do
        sender = users(:one)
        token  = JsonWebToken.encode(user_id: sender.id)

        post api_v1_transfers_url,
          params: { transfer: { sender_id: sender.id, receiver_id: SecureRandom.uuid, amount_cents: 100 } },
          headers: { "Authorization" => "Bearer #{token}" },
          as: :json

        assert_response :not_found
        json = response.parsed_body
        assert json["error"].present?
      end

      # POST /api/v1/transfers — insufficient funds
      test "returns 422 when transfer amount exceeds sender balance" do
        sender   = users(:one)
        receiver = users(:two)
        token    = JsonWebToken.encode(user_id: sender.id)

        post api_v1_transfers_url,
          params: { transfer: { sender_id: sender.id, receiver_id: receiver.id, amount_cents: 999_999 } },
          headers: { "Authorization" => "Bearer #{token}" },
          as: :json

        assert_response :unprocessable_entity
        json = response.parsed_body
        assert json["error"].present?
      end

      # POST /api/v1/transfers — balance unchanged on failure
      test "does not change balances when transfer fails due to insufficient funds" do
        sender   = users(:one)
        receiver = users(:two)
        token    = JsonWebToken.encode(user_id: sender.id)
        original_sender_balance   = sender.balance_cents
        original_receiver_balance = receiver.balance_cents

        post api_v1_transfers_url,
          params: { transfer: { sender_id: sender.id, receiver_id: receiver.id, amount_cents: 999_999 } },
          headers: { "Authorization" => "Bearer #{token}" },
          as: :json

        assert_response :unprocessable_entity
        json = response.parsed_body
        assert json["error"].present?
        assert_equal original_sender_balance,   sender.reload.balance_cents
        assert_equal original_receiver_balance, receiver.reload.balance_cents
      end
    end
  end
end
