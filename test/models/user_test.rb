require "test_helper"

class UserTest < ActiveSupport::TestCase
  # email validations
  test "valid user with proper email" do
    user = User.new(email: "valid@example.com")
    assert user.valid?
  end

  test "invalid without email" do
    user = User.new(email: "")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with malformed email" do
    user = User.new(email: "notanemail")
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "invalid with duplicate email (case-insensitive)" do
    user = User.new(email: users(:one).email.upcase)
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  # balance_cents validations
  test "valid with zero balance_cents" do
    user = User.new(email: "zero@example.com", balance_cents: 0)
    assert user.valid?
  end

  test "invalid with negative balance_cents" do
    user = User.new(email: "neg@example.com", balance_cents: -1)
    assert_not user.valid?
    assert user.errors[:balance_cents].any?
  end
end
