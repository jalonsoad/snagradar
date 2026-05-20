require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "rejects a duplicate email address with a friendly message" do
    other = User.new(
      email_address: users(:one).email_address.upcase,  # case-insensitive
      password:      "anotherpass123",
      name:          "Duplicate User"
    )
    assert_not other.valid?
    assert_match(/already in use/, other.errors[:email_address].first)
  end

  test "rejects a malformed email" do
    u = User.new(email_address: "not-an-email", password: "password123")
    assert_not u.valid?
    assert_includes u.errors[:email_address].first, "doesn't look right"
  end

  test "accepts a fresh email" do
    u = User.new(email_address: "fresh@example.com", password: "password123", name: "Fresh")
    assert u.valid?, u.errors.full_messages.to_sentence
  end
end
