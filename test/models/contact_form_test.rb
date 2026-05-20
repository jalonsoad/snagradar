require "test_helper"

class ContactFormTest < ActiveSupport::TestCase
  test "valid with all required fields" do
    form = ContactForm.new(
      name: "Sara", company: "Acme", email: "sara@acme.com",
      interest: "demo", message: "We have ten sites and want to see the radar.",
      terms_accepted: true
    )
    assert form.valid?, form.errors.full_messages.to_sentence
  end

  test "rejects missing name and company" do
    form = ContactForm.new(email: "a@b.com", message: "ten characters", terms_accepted: true)
    assert_not form.valid?
    assert_includes form.errors[:name],    "can't be blank"
    assert_includes form.errors[:company], "can't be blank"
  end

  test "rejects malformed email" do
    form = ContactForm.new(name: "S", company: "A", email: "not-an-email",
                           message: "ten characters", terms_accepted: true)
    assert_not form.valid?
    assert_includes form.errors[:email].first, "doesn't look right"
  end

  test "rejects short message" do
    form = ContactForm.new(name: "S", company: "A", email: "a@b.com",
                           message: "too short", terms_accepted: true)
    assert_not form.valid?
    assert_match(/needs at least 10/, form.errors[:message].first)
  end

  test "rejects unaccepted terms" do
    form = ContactForm.new(name: "S", company: "A", email: "a@b.com",
                           message: "Long enough message here.",
                           interest: "demo", terms_accepted: false)
    assert_not form.valid?
    assert_includes form.errors[:terms_accepted], "must be accepted"
  end

  test "rejects unknown interest" do
    form = ContactForm.new(name: "S", company: "A", email: "a@b.com",
                           message: "Long enough message here.",
                           interest: "wedding", terms_accepted: true)
    assert_not form.valid?
  end
end
