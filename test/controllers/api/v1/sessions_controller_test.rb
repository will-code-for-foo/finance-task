require "test_helper"

module Api
  module V1
    class SessionsControllerTest < ActionDispatch::IntegrationTest
      # POST /api/v1/session — success
      test "returns 200 with token for existing user" do
        post api_v1_session_url,
          params: { session: { email: "alice@example.com" } },
          as: :json

        assert_response :ok
        json = response.parsed_body
        assert json["token"].present?
      end

      # POST /api/v1/session — case-insensitive email
      test "returns 200 with token for email with different case" do
        post api_v1_session_url,
          params: { session: { email: "ALICE@example.com" } },
          as: :json

        assert_response :ok
        json = response.parsed_body
        assert json["token"].present?
      end

      # POST /api/v1/session — unknown email
      test "returns 401 for unknown email" do
        post api_v1_session_url,
          params: { session: { email: "nonexistent@example.com" } },
          as: :json

        assert_response :unauthorized
        json = response.parsed_body
        assert_equal "Invalid email", json["error"]
      end

      # POST /api/v1/session — missing email
      test "returns 401 when email is blank" do
        post api_v1_session_url,
          params: { session: { email: "" } },
          as: :json

        assert_response :unauthorized
        json = response.parsed_body
        assert_equal "Invalid email", json["error"]
      end

      # POST /api/v1/session — no auth required
      test "does not require authentication" do
        post api_v1_session_url,
          params: { session: { email: "alice@example.com" } },
          as: :json

        assert_response :ok
      end

      test "returns 400 when email param is missing" do
        post api_v1_session_url,
          params: { session: {} },
          as: :json

        assert_response :bad_request
      end

      test "returns 400 when session param is missing" do
        post api_v1_session_url,
          params: {},
          as: :json

        assert_response :bad_request
      end

      test "returns 401 when email is nil" do
        post api_v1_session_url,
          params: { session: { email: nil } },
          as: :json

        assert_response :unauthorized
        json = response.parsed_body
        assert_equal "Invalid email", json["error"]
      end

      test "returns 401 when email is whitespace" do
        post api_v1_session_url,
          params: { session: { email: "   " } },
          as: :json

        assert_response :unauthorized
        json = response.parsed_body
        assert_equal "Invalid email", json["error"]
      end

      test "returns 401 when email is not a string" do
        post api_v1_session_url,
          params: { session: { email: 12345 } },
          as: :json

        assert_response :unauthorized
        json = response.parsed_body
        assert_equal "Invalid email", json["error"]
      end

      test "returns 200 with token for email with leading whitespace" do
        post api_v1_session_url,
          params: { session: { email: " alice@example.com" } },
          as: :json
        assert_response :ok
        json = response.parsed_body
        assert json["token"].present?
      end

      test "returns 200 with token for email with trailing whitespace" do
        post api_v1_session_url,
          params: { session: { email: "alice@example.com " } },
          as: :json
        assert_response :ok
        json = response.parsed_body
        assert json["token"].present?
      end

      test "returns 200 with token for email with leading and trailing whitespace" do
        post api_v1_session_url,
          params: { session: { email: " alice@example.com " } },
          as: :json
        assert_response :ok
        json = response.parsed_body
        assert json["token"].present?
      end

      # POST /api/v1/session — returned token encodes the correct user id
      test "returned token encodes the authenticated user id" do
        post api_v1_session_url,
          params: { session: { email: "alice@example.com" } },
          as: :json

        assert_response :ok
        token = response.parsed_body["token"]
        payload = JsonWebToken.decode(token)
        assert_equal users(:one).id, payload[:user_id]
      end
    end
  end
end
