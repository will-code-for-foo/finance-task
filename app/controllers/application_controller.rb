class ApplicationController < ActionController::API
  before_action :authenticate_request!

  rescue_from StandardError, with: :render_internal_error
  rescue_from FinancialTransactionService::InvalidInputError, with: :render_unprocessable
  rescue_from FinancialTransactionService::InsufficientFundsError, with: :render_unprocessable
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def authenticate_request!
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last

    unless token
      render json: { error: "Missing authorization token" }, status: :unauthorized
      return
    end

    begin
      decoded = JsonWebToken.decode(token)
      @current_user = User.find(decoded[:user_id])
    rescue JWT::ExpiredSignature
      render json: { error: "Token has expired" }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { error: "Invalid token" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    end
  end
  def render_unprocessable(e)  = render json: { error: e.message }, status: :unprocessable_entity
  def render_record_invalid(e) = render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  def render_not_found(e)      = render json: { error: e.message }, status: :not_found
  def render_internal_error(e)
    Rails.logger.error("#{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}")
    render json: { error: "Internal server error" }, status: :internal_server_error
  end
end
