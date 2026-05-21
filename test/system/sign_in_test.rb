require "application_system_test_case"

class SignInTest < ApplicationSystemTestCase
  test "user signs in and lands on the dashboard" do
    user = users(:one)

    visit new_session_path
    # Labels in our sign-in form aren't `for=`-bound to the inputs, so target
    # by input id / placeholder which Capybara also resolves.
    fill_in "email_address", with: user.email_address
    fill_in "password",      with: "password123"
    click_button "Sign in"

    # Authentication#after_authentication_url is overridden to /dashboard.
    assert_current_path dashboard_path
    assert_selector "h1", text: /welcome/i
  end
end
