require "test_helper"

module Api
  module V1
    class UsersControllerTest < ActionDispatch::IntegrationTest
      test "creates a user and returns 201 with token" do
        post api_v1_users_url,
          params: { user: { email: "newuser@example.com" } },
          as: :json

        assert_response :created
        json = response.parsed_body
        assert_equal "newuser@example.com", json["user"]["email"]
        assert_equal "0.00", json["user"]["balance"]
        assert json["token"].present?
      end

      test "returns 422 when email is missing" do
        post api_v1_users_url,
          params: { user: { email: "" } },
          as: :json

        assert_response :unprocessable_entity
        json = response.parsed_body
        assert json["errors"].present?
      end

      test "returns 422 when email is already taken" do
        post api_v1_users_url,
          params: { user: { email: "alice@example.com" } },
          as: :json

        assert_response :unprocessable_entity
        json = response.parsed_body
        assert_includes json["errors"], "Email already exists"
      end

      test "returns 422 when email is already taken with different case" do
        post api_v1_users_url,
          params: { user: { email: "ALICE@EXAMPLE.COM" } },
          as: :json

        assert_response :unprocessable_entity
        json = response.parsed_body
        assert_includes json["errors"], "Email already exists"
      end

      test "does not require authentication" do
        post api_v1_users_url,
          params: { user: { email: "noauth@example.com" } },
          as: :json

        assert_response :created
      end
    end
  end
end
